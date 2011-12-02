module Marley
  module Plugins
    class Tagging < Plugin
      module ClassMethods
        def tagging(user_class=nil)
          @tag_join_table=:"#{table_name}_tags"
          @tag_key=:tag_id
          if user_class
            current_user_tags=Module.new do
              def current_user_dataset
                filter(:tags__user_id => $request[:user][:id])
              end
            end
            MR::UserTag.many_to_many resource_name.to_sym,:class => self, :join_table => @tag_join_table,:left_key => @tag_key,:right_key => foreign_key_name.to_sym,:extend => current_user_tags
            many_to_many :user_tags, :class => 'Marley::Resources::UserTag',:join_table => @tag_join_table,:left_key => foreign_key_name.to_sym,:right_key => @tag_key, :extend => [current_user_tags,Marley::RestActions]
            Marley::Resources.const_get(user_class).one_to_many :user_tags, :class => 'Marley::Resources::UserTag'
            MR::UserTag.many_to_one user_class.underscore.to_sym,:class => "Marley::Resources::#{user_class}"
          else
            MR::PublicTag.many_to_many self.resource_name.to_sym,:class => self, :join_table => @tag_join_table,:left_key => @tag_key,:right_key => foreign_key_name.to_sym
            many_to_many :public_tags,:class => "MR::PublicTag",:join_table => @tag_join_table,:left_key => foreign_key_name.to_sym,:right_key => @tag_key, :extend => Marley::RestActions
          end
        end
        def list(params={})
          if associations.include?(:public_tags)
            specified_tags=params.delete(:tags)
            specified_user_tags=params.delete(:user_tags)
          else
            specified_user_tags=params.delete(:tags)
          end
          @tag_ids=MR::PublicTag.filter(:tag => specified_tags.split(/\s*,\s*/)).select(:id) if specified_tags
          @user_tag_ids=$request[:user].user_tags_dataset.filter(:tag => specified_user_tags.split(/\s*,\s*/)).select(:id) if specified_user_tags
          @items=filter(params)
          @items=@items.join(@tag_join_table,foreign_key_name.to_sym => :id).filter(@tag_key => @tag_ids) if specified_tags
          @items=@items.join(@tag_join_table,foreign_key_name.to_sym => :id).filter(@tag_key => @user_tag_ids) if specified_user_tags
        end
      end
      module InstanceMethods
        def rest_associations
          if ! new?
            [ respond_to?(:public_tags) ? :public_tags : nil, respond_to?(:user_tags) ? user_tags_dataset.current_user_dataset : nil].compact
          end
        end
        def new_tags
          [:instance,{:name => 'tags',:url => "#{url}/tags", :new_rec => true, :schema => [['number',"#{self.class.resource_name}_id",RESTRICT_HIDE,id],['text','tags',RESTRICT_REQ]]}]
        end
        def new_user_tags
          [:instance,{:name => 'user_tags',:url => "#{url}/user_tags", :new_rec => true, :schema => [['number',"user_tags[#{self.class.resource_name}_id]",RESTRICT_HIDE,id],['text','user_tags[tags]',RESTRICT_REQ]]}]
        end
        def add_tags(tags,user=nil)
          if respond_to?(:public_tags)
            tags.to_s.split(',').each {|tag| add_public_tag(MR::PublicTag.find_or_create(:tag => tag))}
          else
            add_user_tags(tags,user)
          end
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
      end
    end
  end
  module Joints
    class Tagging < Joint
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
          @actions_delete='remove_parent'
        end
        class UserTag < Tag
          set_dataset DB[:tags].filter(~{:user_id => nil})
          @actions_delete='remove_parent'
        end
      end
    end
  end
end
