module Marley
  module Plugins
    class Tagging < Plugin
      module ClassMethods
        def tagging(user_class=nil)
          join_table=:"#{self.table_name}_tags"
          klass_key=:"#{self.table_name.to_s.singularize}_id"
          tag_key=:tag_id
          if user_class
          current_user_tags=Module.new do
              def current_user_dataset
                filter(:tags__user_id => $request[:user][:id])
              end
            end
            MR::UserTag.many_to_many self.resource_name.to_sym,:class => self, :join_table => join_table,:left_key => tag_key,:right_key => klass_key,:extend => current_user_tags
            many_to_many :user_tags, :class => 'Marley::Resources::UserTag',:join_table => join_table,:left_key => klass_key,:right_key => tag_key, :extend => [current_user_tags,Marley::RestActions]
            Marley::Resources.const_get(user_class).one_to_many :user_tags, :class => 'Marley::Resources::UserTag'
            MR::UserTag.many_to_one user_class.underscore.to_sym,:class => "Marley::Resources::#{user_class}"
          else
            MR::PublicTag.many_to_many self.resource_name.to_sym,:class => self, :join_table => join_table,:left_key => tag_key,:right_key => klass_key
            many_to_many :public_tags,:class => "MR::PublicTag",:join_table => join_table,:left_key => klass_key,:right_key => tag_key, :extend => Marley::RestActions
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
