require 'sanitize'

module Marley
  module Joints
    class BasicMessaging < Joint
      def add_resources
        super
        if @opts[:tagging]
          Marley.joint 'tagging'
          Resources::Message.tagging(@opts[:tagging_user_class])
        end
      end
      module Resources
        class Message < Sequel::Model
          plugin :single_table_inheritance, :message_type, :model_map => lambda{|v| name.sub(/Message/,v.to_s)}, :key_map => lambda{|klass|klass.name.sub(/.*::/,'')}
          plugin :tree
          many_to_one :author, :class => :'Marley::Resources::User'
          def self.tagging(user_class=nil)
            Post.tagging(user_class)
            PrivateMessage.tagging(user_class)
            include MR::Tag::TaggingMethods
            extend MR::Tag::TaggingClassMethods
          end
          @owner_col=:author_id
          def rest_cols; [:id,:author_id,:message,:title,:parent_id]; end
          def write_cols; new? ?  rest_cols - [:id] : []; end
          def required_cols; write_cols - [:parent_id]; end
          def rest_schema
            schema=super
            schema << [:text,:author,RESTRICT_RO,author.to_s]
            if new?
              schema << [:text, :tags, 0,tags] if respond_to?(:tags) 
              schema << [:text, :my_tags, 0,my_tags] if respond_to?(:my_tags)
            end
            schema
          end
          def authorize_rest_get(meth)
            current_user_role && (meth.nil? || self.class.instance_get_actions.include?(meth))
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
          def self.tagging(user_class)
            attr_accessor :tags
            @instance_get_actions << 'new_tags'
            MR::Tag.tagging_for('PrivateMessage', user_class)
            include MR::Tag::UserTaggingMethods
          end
          @instance_get_actions=['reply','reply_all']
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
            self.class.new({:parent_id => self[:id],:author_id => $request[:user][:id],:recipients => author.name, :title => "re: #{title}", :tags => (user_tags_dataset.current_user_tags.map{|t|t.tag} - RESERVED_PM_TAGS).join(',')})
          end
          def reply_all
            foo=reply
            foo.recipients="#{author.name},#{recipients}".gsub(/\b(#{$request[:user][:name]})\b/,'').sub(',,',',')
            foo
          end
          def after_create
            if respond_to?(:user_tags)
              add_user_tags("inbox,#{tags}",recipients)
              add_user_tags("sent,#{recipients.match(/\b#{author.name}\b/) ? '' : tags}",author_id)
            end
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
          def self.tagging(user_class=nil)
            attr_accessor :tags,:my_tags
            if user_class
              MR::Tag.tagging_for('Post', user_class)
              @instance_get_actions << 'new_user_tags'
            end
            MR::Tag.tagging_for('Post')
            @instance_get_actions << 'new_tags'
            include MR::Tag::PublicTaggingMethods
            include MR::Tag::UserTaggingMethods
          end
          @instance_get_actions=['reply']
          def current_user_role
            super || 'reader'
          end
          def authorize_rest_post(meth);true;end
          def after_create
            add_tags(tags) if respond_to?(:public_tags) && tags
            add_user_tags(my_tags) if respond_to?(:user_tags) && my_tags
          end
          def reply
            self.class.new({:parent_id => self[:id],:author_id => $request[:user][:id],:tags => self.tags, :title => "re: #{title}"})
          end
        end
      end
    end
  end
end
