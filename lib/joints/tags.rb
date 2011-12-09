module Marley
  module Plugins
    class Tagging < Plugin
      @default_opts={:join_type => 'many_to_many'}
      def apply(*klasses)
        super
        klasses.each do |klass|
          klass=MR.const_get(klass) if klass.class==String
          tag_class=MR.const_get(@opts[:tag_class_name])
          join_type=@opts[:"#{klass}_join_type"] || @opts[:join_type]
          if join_type=='many_to_many'
            Marley::Utils.many_to_many_join(klass, tag_class)
          else
            reciprocal_join=join_type.split('_').reverse.join('_')
            tag_class.send(reciprocal_join.to_sym, klass.resource_name.pluralize.to_sym, {:class => klass})
            klass.send(join_type.to_sym, tag_class.resource_name.pluralize.to_sym, {:class => tag_class})
          end
        end
      end
    end
    class PrivateTagging < Tagging
      @default_opts=@default_opts.merge(:tag_class_name => 'PrivateTag')
      module InstanceMethods
        def rest_associations;super << private_tags.filter(:user_id => $request[:user][:id]);end
        def new_user_tags
          [:instance,{:name => 'user_tags',:url => "#{url}/user_tags", :new_rec => true, :schema => [['number',"user_tags[#{self.class.resource_name}_id]",RESTRICT_HIDE,id],['text','user_tags[tags]',RESTRICT_REQ]]}]
        end
        def add_user_tags(tags,user=nil) #does not conflict with add_user_tag
          user||=$request[:user][:id]
          if user.class==String
            user.split(',').each {|u| add_user_tags(tags,MR::User[:name => u][:id])}
          elsif user.class==Array
            user.each {|u| add_user_tags(tags,u)}
          elsif user.class==Fixnum
            tags.to_s.split(',').each {|tag| add_user_tag(MR::UserTag.find_or_create(:user_id => user, :tag => tag))}
          end
        end
        def reggae_schema
          foo=super
          [:public_tags,:private_tags].each do |tag_type|
            foo << [:text,tag_type,0,nil] if self.class.associations.include?(tag_type)
          end
          foo
        end
      end
    end
    class PublicTagging < Tagging
      @default_opts=@default_opts.merge(:tag_class_name => 'PublicTag')
      #@default_opts[:tag_class_name] = 'PublicTag'
      module InstanceMethods
        def rest_associations;super << public_tags;end
        def new_public_tags
          [:instance,{:name => 'tags',:url => "#{url}/tags", :new_rec => true, :schema => [['number',"#{self.class.resource_name}_id",RESTRICT_HIDE,id],['text','tags',RESTRICT_REQ]]}]
        end
        def add_public_tags(tags,user=nil)
          tags.to_s.split(',').each {|tag| add_public_tag(MR::PublicTag.find_or_create(:tag => tag))}
        end
      end
    end
  end
  module Joints
    class Tags < Joint
      module Resources
        class Tag < Sequel::Model
          def validate
            validates_presence :tag
            validates_unique [:tag,:user_id]
          end
          def before_save
            super
            self.tag.downcase!
            self.tag.strip!
          end
          def after_save
            super
            assoc=methods.grep(/_id=$/) - ['user_id=']
            assoc.each do |a|
              if c=self.send(a.sub(/=$/,''))
                send "add_#{a.sub(/_id=/,'')}", Marley::Resources.const_get(a.sub(/_id=/,'').camelize.to_sym)[c]
              end
            end
          end
        end
        class PublicTag < Tag
          set_dataset DB[:tags].filter(:user_id => nil)
#          @actions_delete='remove_parent'
        end
        class PrivateTag < Tag
          Marley.plugin('current_user_methods').apply(self)
          def self.list_dataset
            current_user_dataset
          end
#          @actions_delete='remove_parent'
        end
      end
    end
  end
end
