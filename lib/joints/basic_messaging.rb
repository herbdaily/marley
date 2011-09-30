require 'sanitize'

module Marley
  #tagging joint must be loaded before any of these is run
  def self.message_tagging(user_class=nil)
    self.post_tagging(user_class)
    self.pm_tagging(user_class) if user_class
  end
  def self.post_tagging(user_class=nil)
    tagging_for('Post', user_class)
  end
  def self.pm_tagging(user_class)
    tagging_for('PrivateMessage', user_class)
  end

  module Resources
    class Message < Sequel::Model
      plugin :single_table_inheritance, :message_type, :model_map => lambda{|v| name.sub(/Message/,v.to_s)}, :key_map => lambda{|klass|klass.name.sub(/.*::/,'')}
      plugin :tree
      many_to_one :author, :class => :'Marley::Resources::User'
      @owner_col=:author_id
      def rest_schema
        schema=super
        schema << [:text,:author,RESTRICT_RO,author.to_s]
        if new?
          schema << [:text, :tags, 0,tags] if (respond_to?(:tags) && (respond_to?(:public_tags) || respond_to?(:user_tags)) )
          schema << [:text, :my_tags, 0,my_tags] if respond_to?(:user_tags) && respond_to?(:my_tags)
        end
        schema
      end
      def write_cols
        new? ?  [:message,:title,:parent_id] : []
      end
      def required_cols; write_cols - [:parent_id]; end
      def authorize_rest_get(meth)
        self.class.instance_get_actions.include?(meth)
      end
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
        validates_type User, :author
      end
      def thread
        to_a << children.map{|m| m.thread}
      end
      def to_a
        a=super
      end
    end
    class PrivateMessage < Message
      attr_reader :tags
      @instance_get_actions=['reply','reply_all']
      def write_cols;new? ? super << :recipients : super;end
      def required_cols;new? ? super << :recipients : [];end
      def authorize_rest_put(meth); false; end
      def authorize_rest_get(meth)
        super && ($request[:user]==author || self.recipients.match(/\b#{$request[:user].name}\b}/))
      end
      def self.authorize_rest_post(asdf)
        true #may need to change this, for now auth is handled in validation
      end
      def after_initialize
        super
        @tags=user_tags.current_user_tags.map{|t| t.tag}.join(",") unless new?
      end
      def reply
        self.class.new({:parent_id => self[:id],:author_id => $request[:user][:id],:recipients => author.name, :title => "re: #{title}"})
      end
      def reply_all
        foo=reply
        foo.recipients="#{author.name},#{recipients}".gsub(/\b(#{$request[:user][:name]})\b/,'').sub(',,',',')
        foo
      end
      def after_create
        if respond_to?(:user_tags)
          recipients.split(',').each do |recipient|
            "inbox,#{tags}".split(/\s*,\s*/).each do |tag|
              t={:user_id => User[:name => recipient][:id],:tag =>tag}
              add_user_tag(UserTag[t] || UserTag.create(t))
            end
          end
          if  ! recipients.match(/\b#{author.name}\b/)
            "sent,#{tags}".split(/\s*,\s*/).each do |tag|
              t={:user_id => author_id,:tag =>tag}
              add_user_tag(UserTag[t] || UserTag.create(t))
            end
          end
        end
      end
      def validate
        super
        validates_presence [:recipients]
        self.recipients.split(',').each do |recipient|
          errors.add(:recipients, "Invalid user: #{recipient}") unless User[:name => recipient]
        end
        if $request[:user].class==User
          self.recipients.split(',').each do |recipient|
            errors.add(:recipients, "You may only send PM's to Admins or Mods. #{recipient} is neither of those") unless ['Admin','Moderator'].include?(User[:name => recipient].user_type)
          end
        end
      end
    end
    class Post < Message
      attr_writer :tags,:my_tags
      @instance_get_actions=['reply']
      def tags
        public_tags.map{|t| t.tag}.join(",") unless new?
      end
      def my_tags
        user_tags.current_user_tags.map{|t| t.tag}.join(",") unless new?
      end
      def after_create
        tags.split(/\s*,\s*/).each {|tag| add_message_tag({:user_id => nil,:tag =>tag})} if respond_to?(:public_tags) && tags
        my_tags.split(/\s*,\s*/).each {|tag| add_message_tag({:user_id => $request[:user][:id],:tag =>tag})} if respond_to?(:user_tags) && my_tags
      end
      def reply
        self.class.new({:parent_id => self[:id],:author_id => $request[:user][:id],:tags => self.tags, :title => "re: #{title}"})
      end
    end
  end
end
