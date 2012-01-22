module Marley
  module Joints
    class Messages < Joint
      def smoke
        super
        if @opts[:tags]
          Marley.joint('tags')
          Marley.plugin(:tagging,{:tag_type => 'private'}).apply(Resources::PrivateMessage)
          Marley.plugin(:tagging,{:tag_type => 'private'}).apply(Resources::PublicMessage)
          Marley.plugin(:tagging,{:tag_type => 'public'}).apply(Resources::PublicMessage)
        end
      end
      class Message < Sequel::Model
        MU.sti(self)
        MR::User.join_to(self) if MR::User
        instance_actions![:new?][false]={:get => 'reply'}
        derived_before_cols![:new?][false]=[:author]
        ro_cols![:current_user_role] = {'reader' => [/.*/],'owner' => [/^author$/]}
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
      module Resources
        class PrivateMessage < Message
          ro_cols![:new?]={false => [/.*/], true => ['id', 'user_id','author']}
          attr_writer :recipients
          def rest_cols
            [:recipients] + super
          end
          Marley::Utils.many_to_many_join(self, MR::User)
          def self.list_dataset
            filter(:id => DB[:messages_users].filter(:user_id => current_user[:id]).select(:message_id))
          end
          def current_user_role
            super || (self.users.include?(self.class.current_user) && 'recipient')
          end
          def actions(parent_instance=nil)
            return super if new? || ! recipients.to_s.match(/,/) 
            [:reply, :reply_all]
          end
          def recipients
            users.map{|u|u.name}.join(',')
          end
          def reply
            super.reggae_instance.set_values(:recipients => author)
          end
          def reply_all
            reply.set_values(:recipients => "#{author},#{recipients}".sub(/\b#{self.class.current_user.name}\b,?/,''))
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
          def current_user_role
            super || 'reader' 
          end
          def actions(parent_instance=nil)
            if current_user_role=='owner' && ! self.new?
              {:delete => self.url}.update(super || {})
            else
              super
            end
          end
        end
      end
    end
  end
end
