module Marley
  module Joints
    class Tagging < Joint
      module Resources
        class Tag < Sequel::Model
          def self.tagging_for(klass, user_class=nil,join_table=nil)
            current_user_tags=Module.new do
                def current_user_dataset
                  filter(:tags__user_id => $request[:user][:id])
                end
              end
            tagged_class=Marley::Resources.const_get(klass.to_sym)
            join_table||=:"#{tagged_class.table_name}_tags"
            klass_key=:"#{tagged_class.table_name.to_s.singularize}_id"
            tag_key=:tag_id
            if user_class
              UserTag.many_to_many klass.underscore.to_sym,:class => "Marley::Resources::#{klass}", :join_table => join_table,:left_key => tag_key,:right_key => klass_key,:extend => current_user_tags
              tagged_class.many_to_many :user_tags, :class => 'Marley::Resources::UserTag',:join_table => join_table,:left_key => klass_key,:right_key => tag_key, :extend => [current_user_tags,Marley::Orm::RestActions]
              Marley::Resources.const_get(user_class).one_to_many :user_tags, :class => 'Marley::Resources::UserTag'
              UserTag.many_to_one user_class.underscore.to_sym,:class => "Marley::Resources::#{user_class}"
            else
              PublicTag.many_to_many klass.underscore.to_sym,:class => "Marley::Resources::#{klass}", :join_table => join_table,:left_key => tag_key,:right_key => klass_key
              tagged_class.many_to_many :public_tags,:class => "Marley::Resources::PublicTag",:join_table => join_table,:left_key => klass_key,:right_key => tag_key, :extend => Marley::Orm::RestActions
            end
          end
          def to_a
            a=super
            a.actions[:delete]='remove_parent'
            a
          end
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
        end
        class UserTag < Tag
          set_dataset DB[:tags].filter(~{:user_id => nil})
        end
      end
    end
  end
end
