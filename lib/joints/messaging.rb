require 'sanitize'
module Marley
  module Plugins
    class MessageThreading < Plugin
      def apply(klass)
        klass.plugin :tree
        super
      end
      module ClassMethods
      end
      module InstanceMethods
        def after_initialize
          super
          if new?
            self.thread_id=parent ? parent.thread_id : DB[self.class.table_name].select(:max.sql_function(:thread_id).as(:tid)).all[0][:tid].to_i + 1
          end
        end
        def thread
          children.length > 0 ? to_a << children.map{|m| m.thread} : to_a
        end
      end
    end
    class MessageTagging < Plugin
      def initialize(*opts)
        super
        Marley.joint 'tagging'
        @tag_plugin=Marley.plugin('tagging')
        @tag_plugin.apply(Resources::Message) 
      end
      def apply(klass,user_klass=nil)
        klass.tagging(user_klass)
        super(klass)
      end
      module ClassMethods
      end
      module InstanceMethods
        attr_accessor :tags,:user_tags
      end
    end
  end
  module Joints
    class Messaging < Joint
      def smoke
        if @opts[:threaded]
          Marley.plugin('message_threading').apply(Resources::Message)
        end
        if @opts[:tagged]
          Resources::PrivateMessage.tagging('User')
          Resources::PublicMessage.tagging('User')
          Resources::PublicMessage.tagging()
        end
        super
      end
      module Resources
        class Message < Sequel::Model
          plugin :single_table_inheritance, :message_type, :model_map => lambda{|v| v ? MR.const_get(v.to_s) : ''}, :key_map => lambda{|klass|klass.name.sub(/.*::/,'')}
          many_to_one :author, :class => :'Marley::Resources::User'
          @owner_col=:author_id
          def rest_cols; [:id,:author_id,:message,:title,:parent_id]; end
          def write_cols; new? ?  rest_cols - [:id] : []; end
          def required_cols; write_cols - [:parent_id]; end
          def rest_schema
            super << [:text,:author,RESTRICT_RO,author.to_s]
          end
          def authorize_rest_get(meth)
            current_user_role && (meth.nil? || self.class.actions_get.include?(meth))
          end
          def authorize_rest_put(meth); false; end
          def before_save
            self.message=Sanitize.clean(self.message,:elements => %w[blockquote em strong ul ol li p code])
          end
          def validate
            validates_presence [:author,:message,:title]
            validates_type MR::User, :author
          end
        end
        class PrivateMessage < Message
          @actions_get=['reply','reply_all']
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
              errors.add(:recipients, "Invalid user: #{recipient}") unless MR::User[:name => recipient]
            end
          end
        end
        class PublicMessage < Message
          @actions_get=['reply']
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


