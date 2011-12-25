module Marley
  module Joints
    class Messages < Joint
      module Resources
        class Message < Sequel::Model
          sti # sets single_table_inheritance plugin
          def validate
            super
            validates_presence [:title]
          end
        end
        class PrivateMessage < Message
          User.join_to(self)
          def self.list_dataset
            current_user_ds
          end
          def validate
            super
            validates_presence [:recipients]
          end
        end
        class PublicMessage < Message
          ro_cols[:current_user_role]={'reader' => [/.*/]}
          def current_user_role
            super || 'reader' unless User.current_user.new?
          end
          def actions(parent_instance=nil)
            {:delete => self.url} if current_user_role=='owner' && ! self.new?
          end
        end
      end
    end
  end
end
