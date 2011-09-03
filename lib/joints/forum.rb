#require 'sanitize'

module Marley
  module Resources
    class User 
      plugin :single_table_inheritance, :user_type, :model_map => lambda{|v| name.sub(/User/,v.to_s)}, :key_map => lambda{|klass|klass.name.sub(/.*::/,'')}
      one_to_many :message_tags 
      def pm_tags
        private_message_tags.map{|t| t.tag }.compact
      end
      def private_messages(params)
        params.each_pair {|k,v| params[k]=" #{v}" if RESERVED_PM_TAGS.include?(v)}
        params[:user_id]=self.id
        DB[message_tags_dataset.filter(params).join('messages', :id => :message_id).select(:thread_id).group(:thread_id).order(:max.sql_function(:date_created).desc)].map{|t|PrivateMessage[:parent_id => nil, :thread_id => t[:thread_id]].thread}
      end
      def post_tags
        MessageTag.filter(:user_id => nil)
      end
      def posts(params)
        if params[:untagged].to_s=='true'
          threads=Post.filter('(select count(*) from message_tags where message_id=messages.id)=0'.lit).group(:thread_id)
        else
          params.each_pair {|k,v| params[k]=" #{v}" if RESERVED_POST_TAGS.include?(v)}
          threads=DB[MessageTag.filter(params.merge({:user_id => nil})).join('messages', :id => :message_id).group(:thread_id)]
        end
        threads.order(:max.sql_function(:date_created).desc,:max.sql_function(:date_updated).desc).map{|t|Post[:parent_id => nil, :thread_id => t[:thread_id]].thread}
      end
      def private_messages_menu
        { :title => 'Private Messages',
        :name => 'private_messages',
        :items => $request[:user].message_tags_dataset.group(:tag).select(:tag).map{|t| [:resource,{:url => "/private_message?private_message[tag]=#{t.tag}",:title => t.tag.humanize}]}.unshift(PrivateMessage.json_resource('new')) }
      end
      def public_messages_menu
        { :title => 'Public Messages',
        :name => 'public_messages',
        :items => MessageTag.filter(:user_id => nil).group(:tag).select(:tag).map{|t| [:resource,{:url => "/post?post[tag]=#{t.tag}",:title => t.tag.humanize}]}.unshift([:resource,{:url => '/post?post[untagged]=true',:title => 'Untagged Messages'}]).unshift(Post.json_resource('new')) }
      end
    end
    class Admin < User 
      def self.requires_user?;true;end
    end
    class Moderator < User
      def self.requires_user?;true;end
    end

    class MessageTag < Sequel::Model
      many_to_one :message
      many_to_one :user
      def json_resource
        [:resource, {:url => "/messages_tag/#{id}",:updatable => true,:deletable => true,:title => tag.tag.humanize}]
      end
      def after_initialize
        self.tag.strip!
      end
      def before_save
        self.tag.downcase!
        self.tag.strip!
        self.tag=" #{tag}" if message.class==PrivateMessage && RESERVED_PM_TAGS.include?(self.tag)
        self.tag=" #{tag}" if message.class==Post && RESERVED_POST_TAGS.include?(self.tag)
      end
    end
    class Message < Sequel::Model
      plugin :single_table_inheritance, :message_type, :model_map => lambda{|v| name.sub(/Message/,v.to_s)}, :key_map => lambda{|klass|klass.name.sub(/.*::/,'')}
      plugin :tree
      many_to_one :author, :class => User
      one_to_many :message_tags
      attr_accessor :tags
      def write_cols;new? ? [:message,:title,:tags,:parent_id] : [:tags];end
      def required_cols; write_cols - [:parent_id]; end
      @owner_col=:author_id
      def rest_schema
        schema=super
        schema.rassoc(:parent_id)[RESTRICTIONS_INDEX]=RESTRICT_HIDE
        schema << [:text, :tags, 0,tags]
        schema
      end
      def after_initialize
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
      def to_s
        title
      end
      def thread
        to_a << children.map{|m| m.thread}
      end
    end
    class PrivateMessage < Message
      def rest_cols;super.reject {|c| c=="date_updated"};end
      def write_cols;new? ? super << :recipients : super;end
      def required_cols;new? ? super << :recipients : [];end
      @instance_get_actions=['reply','reply_all']
      def authorize_rest_put(meth)
        current_user_tags.count > 0
      end
      def authorize_rest_get(meth)
        self.class.instance_get_actions.include?(meth) && ($request[:user]==author || self.recipients.match($request[:user].name))
      end
      def current_user_tags
        message_tags_dataset.filter(:user_id => $request[:user][:id])
      end
      def after_initialize
        super
        self.tags=current_user_tags.map{|t| t.tag}.join(",") unless new?
      end
      def reply
        self.class.new({:parent_id => self[:id],:author_id => $request[:user][:id],:recipients => author.name, :title => "re: #{title}"})
      end
      def reply_all
        foo=reply
        foo.recipients="#{author.name},#{recipients}".gsub(/\b(#{$request[:user][:name]})\b/,'').sub(',,',',')
        foo
      end
      def update(params)
        current_user_tags.delete
        params[:tags].split(/\s*,\s*/).each {|tag| add_message_tag({:user_id => $request[:user][:id],:tag =>tag})} if tags
      end
      def after_create
        recipients.split(',').each do |recipient|
          add_message_tag({:user_id => User[:name => recipient][:id],:tag =>'inbox'})
          tags.split(/\s*,\s*/).each {|tag| add_message_tag({:user_id => User[:name => recipient][:id],:tag =>tag})} if tags
        end
        add_message_tag({:user_id => author_id,:tag =>'sent'})
        tags.split(/\s*,\s*/).each {|tag| add_message_tag({:user_id => author_id,:tag =>tag})} if tags && ! recipients.match(/\b#{author.name}\b/)
      end
      def validate
        super
        validates_presence [:recipients]
        self.recipients.split(',').each do |recipient|
          errors.add(:recipients, "Invalid user: #{recipient}") unless User[:name => recipient]
        end
        if $request[:user].class==User
          self.recipients.split(',').each do |recipient|
            errors.add(:recipients, "You may only send PM's to Admins, Mods, Vendors and Payees. #{recipient} is none of those") unless [Admin,Moderator,Vendor,Payee].include?(User[:name => recipient].class)
          end
        end
      end
    end
    class Post < Message
      def rest_cols; super - [:recipients]; end
      def write_cols; $request[:user]==author ? [:title,:message,:tags, :parent_id] : [:tags]; end
      @instance_get_actions=['reply']
      def authorize_rest_get(meth)
        self.class.instance_get_actions.include?(meth)
      end
      def after_initialize
        super
        self.tags=message_tags.map{|t| t.tag}.join(",") unless new?
      end
      def after_create
        tags.split(/\s*,\s*/).each {|tag| add_message_tag({:user_id => nil,:tag =>tag})} if tags
      end
      def after_update
        message_tags_dataset.delete
        tags.split(/\s*,\s*/).each {|tag| add_message_tag({:user_id => nil,:tag =>tag})} if tags
      end
      def reply
        self.class.new({:parent_id => self[:id],:author_id => $request[:user][:id],:tags => self.tags, :title => "re: #{title}"})
      end
    end
  end
end
