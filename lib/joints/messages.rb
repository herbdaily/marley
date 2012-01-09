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
            self.class.new(:title => "re: #{title}",:content => content)
          end
          def author
            MR::User[user_id].to_s
          end
        end
        class PrivateMessage < Message
          ro_cols[false]=[/.*/]
          attr_writer :recipients
          def rest_cols
            [:recipients] + super
          end
          Marley::Utils.many_to_many_join(self, MR::User)
          def self.list_dataset
            filter(:id => DB[:messages_users].filter(:user_id => MR::User.current_user[:id]).select(:message_id))
          end
          def actions(parent_instance=nil)
            return super if new? || ! recipients.to_s.match(/,/) 
            [:reply, :reply_all]
          end
          def recipients
            users.map{|u|u.name}.join(',')
          end
          def reply
          end
          def reply_all
          end
          def validate
            super
            errors[:recipients]='Recipients must be specified' unless @recipients
            @recipients=@recipients.split(',').map do |recipient_name|
              u=MR::User[:name => recipient_name]
              errors[:recipients] << "#{recipient_name} is not a valid message recipient" unless u
              u
            end
          end
          def after_save
            super
            @recipients.each {|recipient| add_user recipient} 
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
