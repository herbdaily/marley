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
        attr_accessor :_private_tags
        def rest_cols; super << :_private_tags;end
        def add_private_tags(tags)
          tags.to_s.split(',').each {|tag| self.add_private_tag(MR::PrivateTag.find_or_create(:user_id => $request[:user][:id], :tag => tag)) }
        end
        def after_save
          super
          remove_all_private_tags
          add_private_tags @_private_tags
        end
        def _private_tags
          private_tags.map {|t|t.tag}.join(', ')
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
          def instance_actions(parent_instance)
            {:delete => "#{parent_instance ? parent_instance.url : ''}#{url}"}
          end
          def before_save
            super
            self.tag.downcase!
            self.tag.strip!
          end
        end
        class PublicTag < Tag
          set_dataset DB[:tags].filter(:user_id => nil).order(:tag)
        end
        class PrivateTag < Tag
          Marley.plugin('current_user_methods').apply(self)
          def self.list_dataset
            current_user_dataset.order(:tag)
          end
        end
      end
    end
  end
end
