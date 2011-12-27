module Marley
  module Joints
    class Messages < Joint
      module Resources
        class Message < Sequel::Model
          sti 
          instance_actions[false]={:get => 'reply'}
          MR::User.join_to(self)
          def validate
            super
            validates_presence [:title]
          end
          def reply
            self.new(:title => title,:content => content)
          end
        end
        class PrivateMessage < Message
          ro_cols[:all]=[/.*/]
          Marley::Utils.many_to_many_join(self, MR::User)
          def self.list_dataset
            current_user_ds
          end
          def validate
            super
            validates_presence [:recipients]
          end
          def after_save
            super
          end
        end
        class PublicMessage < Message
          ro_cols[:current_user_role]={'reader' => [/.*/]}
          def current_user_role
            super || 'reader' unless MR::User.current_user.new?
          end
          def actions(parent_instance=nil)
            if current_user_role=='owner' && ! self.new?
              {:delete => self.url}.update(super ? super : {})
            else
              super
            end
          end
        end
      end
    end
  end
end
