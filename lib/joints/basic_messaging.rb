require 'sanitize'

module Marley
  module Resources
    class Message < Sequel::Model
      plugin :single_table_inheritance, :message_type, :model_map => lambda{|v| name.sub(/Message/,v.to_s)}, :key_map => lambda{|klass|klass.name.sub(/.*::/,'')}
      plugin :tree
      many_to_one :author, :class => :'Marley::Resources::User'
      def self.tagging(user_class=nil)
        Post.tagging(user_class)
        PrivateMessage.tagging(user_class)
      end
      def add_public_tags(tags)
        tags.to_s.split(',').each {|tag| add_public_tag(PublicTag.find_or_create(:tag => tag))}
      end
      @owner_col=:author_id
      def write_cols; new? ?  [:message,:title,:parent_id] : []; end
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
      def rest_associations
        if ! new?
          [ respond_to?(:public_tags) ? :public_tags : nil, respond_to?(:user_tags) ? user_tags_dataset.current_user_tags : nil].compact
        end
      end
      def authorize_rest_get(meth)
        current_user_role && (meth.nil? || self.class.instance_get_actions.include?(meth))
      end
      def current_user_role
        super || (recipients.match(/\b#{$request[:user][:name]}\b/) && "recipient")
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
        children.length > 0 ? to_a << children.map{|m| m.thread} : to_a
      end
      def new_tags
        [:instance,{:name => 'tags',:url => "#{url}tags", :new_rec => true, :schema => [['number','tags[message_id]',RESTRICT_HIDE,id],['text','tags[tags]',RESTRICT_REQ]]}]
      end
      def new_user_tags
        [:instance,{:name => 'user_tags',:url => "#{url}user_tags", :new_rec => true, :schema => [['number','user_tags[message_id]',RESTRICT_HIDE,id],['text','user_tags[tags]',RESTRICT_REQ]]}]
      end
      def add_tags(tags,user=nil)
        if respond_to?(:public_tags)
          tags.to_s.split(',').each {|tag| add_public_tag(PublicTag.find_or_create(:tag => tag))}
        else
          add_user_tags(tags,user)
        end
      end
      def add_user_tags(tags,user=nil) #does not conflict with add_user_tag
        user||=$request[:user][:id]
        if user.class==String
          user.split(',').each {|u| add_user_tags(tags,User[:name => u][:id])}
        elsif user.class==Array
          user.each {|u| add_user_tags(tags,u)}
        elsif user.class==Fixnum
          tags.to_s.split(',').each {|tag| add_user_tag(UserTag.find_or_create(:user_id => user, :tag => tag))}
        end
      end
    end
    class PrivateMessage < Message
      def self.tagging(user_class)
        attr_accessor :tags
        @instance_get_actions << 'new_tags'
        Tag.tagging_for('PrivateMessage', user_class)
      end
      @instance_get_actions=['reply','reply_all']
      def write_cols;new? ? super << :recipients : super;end
      def required_cols;new? ? super << :recipients : [];end
      def authorize_rest_get(meth)
        super && ($request[:user]==author || self.recipients.match(/\b#{$request[:user].name}\b/))
      end
      def authorize_rest_post(meth)
        meth.to_s > '' && (author_id==$request[:user][:id] || recipients.match(/\b#{$request[:user][:name]}\b/))
      end
      def authorize_rest_put(meth); false; end
      def self.authorize_rest_post(asdf)
        true #may need to change this, for now auth is handled in validation
      end
      def self.list(params={})
        params||={}
        if specified_tags=params.delete(:tags)
          tag_ids=$request[:user].user_tags_dataset.filter(:tag => specified_tags.split(/\s*,\s*/)).select(:id)
        end
        threads=filter("author_id=#{$request[:user][:id]} or recipients like('%#{$request[:user][:name]}%')".lit)
        threads=threads.filter(params)
        if specified_tags
          threads=threads.join(:messages_tags,:message_id => :id).filter(:tag_id => tag_ids)
        end
        threads.group(:thread_id).order(:max.sql_function(:date_created).desc,:max.sql_function(:date_updated).desc).map{|t|PrivateMessage[:parent_id => nil, :thread_id => t[:thread_id]].thread}
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
          if u=User[:name => recipient]
            errors.add(:recipients, "You may only send PM's to Admins or Mods. #{recipient} is neither of those") unless (['Admin','Moderator'].include?(User[:name => recipient].user_type) || [Admin,Moderator].include?($request[:user].class))
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
          Tag.tagging_for('Post', user_class)
          @instance_get_actions << 'new_user_tags'
        end
        Tag.tagging_for('Post')
        @instance_get_actions << 'new_tags'
      end
      @instance_get_actions=['reply']
      def self.list(params={})
        params||={}
        if specified_tags=params.delete(:tags)
          tag_ids=PublicTag.filter(:tag => specified_tags.split(/\s*,\s*/)).select(:id)
        end
        if specified_user_tags=params.delete(:user_tags)
          user_tag_ids=$request[:user].user_tags_dataset.filter(:tag => specified_tags.split(/\s*,\s*/)).select(:id)
        end
        threads=filter(params)
        if specified_tags
          threads=threads.join(:messages_tags,:message_id => :id).filter(:tag_id => tag_ids)
          if specified_user_tags
            threads=threads.or(:tag_id => user_tag_ids)
          end
        elsif specified_user_tags
          threads=threads.join(:messages_tags,:message_id => :id).filter(:tag_id => user_tag_ids)
        end
        threads.group(:thread_id).order(:max.sql_function(:date_created).desc,:max.sql_function(:date_updated).desc).map{|t|Post[:parent_id => nil, :thread_id => t[:thread_id]].thread}
      end
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
