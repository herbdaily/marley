require 'sanitize'

module Marley
  module Joints
    class BasicMessaging < Joint
      module Resources
        class Message < Sequel::Model
          plugin :single_table_inheritance, :message_type, :model_map => lambda{|v| v ? MR.const_get(v.to_s) : ''}, :key_map => lambda{|klass|klass.name.sub(/.*::/,'')}
          plugin :tree
          many_to_one :author, :class => :'Marley::Resources::User'
          @owner_col=:author_id
          def rest_cols; [:id,:author_id,:message,:title,:parent_id]; end
          def write_cols; new? ?  rest_cols - [:id] : []; end
          def required_cols; write_cols - [:parent_id]; end
          def rest_schema
            super << [:text,:author,RESTRICT_RO,author.to_s]
          end
          def authorize_rest_get(meth)
            current_user_role && (meth.nil? || get_actions.include?(meth))
          end
          def authorize_rest_put(meth); false; end
          def after_initialize
            super
            if new?
              self.author_id=$request[:user][:id]
              self.thread_id=parent ? parent.thread_id : Message.select(:max.sql_function(:thread_id).as(:tid)).all[0][:tid].to_i + 1
            end
          end
          def before_save
            self.message=Sanitize.clean(self.message,:elements => %w[blockquote em strong ul ol li p code])
          end
          def validate
            validates_presence [:author,:message,:title]
            validates_type MR::User, :author
          end
          def thread
            children.length > 0 ? to_a << children.map{|m| m.thread} : to_a
          end
        end
        class PrivateMessage < Message
          def get_actions;['reply','reply_all'];end
          def rest_cols; super << :recipients; end
          def current_user_role
            super || (recipients.match(/\b#{$request[:user][:name]}\b/) && "recipient")
          end
          def authorize_rest_get(meth)
            super && ($request[:user]==author || self.recipients.match(/\b#{$request[:user].name}\b/))
          end
          def authorize_rest_post(meth)
            meth.to_s > '' && (author_id==$request[:user][:id] || recipients.match(/\b#{$request[:user][:name]}\b/))
          end
          def self.authorize_rest_post(asdf)
            true #may need to change this, for now auth is handled in validation
          end
          def reply
            self.class.new({:parent_id => self[:id],:author_id => $request[:user][:id],:recipients => author.name, :title => "re: #{title}"})
          end
          def reply_all
            foo=reply
            foo.recipients="#{author.name},#{recipients}".gsub(/\b(#{$request[:user][:name]})\b/,'').sub(',,',',')
            foo
          end
          def validate
            super
            validates_presence [:recipients]
            self.recipients.split(',').each do |recipient|
              if u=MR::User[:name => recipient]
                errors.add(:recipients, "You may only send PM's to Admins or Mods. #{recipient} is neither of those") unless (['Admin','Moderator'].include?(MR::User[:name => recipient].user_type) || [MR::Admin,MR::Moderator].include?($request[:user].class))
              else
                errors.add(:recipients, "Invalid user: #{recipient}")
              end
            end
          end
        end
        class Post < Message
          def get_actions;['reply'];end
          def current_user_role
            super || 'reader'
          end
          def authorize_rest_post(meth);true;end
          def reply
            self.class.new({:parent_id => self[:id],:author_id => $request[:user][:id], :title => "re: #{title}"})
          end
        end
      end
    end
  end
end
