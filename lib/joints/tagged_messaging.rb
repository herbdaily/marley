
Marley.joint 'basic_user',{:resources => []}
Marley.joint 'tagging'
Marley.joint 'basic_messaging',{:resources => ['Message']}
module Marley
  module Joints
    class TaggedMessaging < Joint
      def smoke
        super
        MR::Tag.tagging_for('PrivateMessage', 'User') if MR.constants.include?('PrivateMessage')
        if MR.constants.include?('Post')
          MR::Tag.tagging_for('Post', 'User')
          MR::Tag.tagging_for('Post')
        end
      end
      module MessagePlugin
        module ClassMethods
          def list(params={})
            if associations.include?(:public_tags)
              specified_tags=params.delete(:tags)
              specified_user_tags=params.delete(:user_tags)
            else
              specified_user_tags=params.delete(:tags)
            end
            tag_ids=MR::PublicTag.filter(:tag => specified_tags.split(/\s*,\s*/)).select(:id) if specified_tags
            user_tag_ids=$request[:user].user_tags_dataset.filter(:tag => specified_user_tags.split(/\s*,\s*/)).select(:id) if specified_user_tags
            items=filter(params)
            #would love to make the following line more generic...
            items=filter("author_id=#{$request[:user][:id]} or recipients like('%#{$request[:user][:name]}%')".lit) if new.rest_cols.include?(:recipients)
            items=items.join(:messages_tags,:message_id => :id).filter(:tag_id => tag_ids) if specified_tags
            items=items.join(:messages_tags,:message_id => :id).filter(:tag_id => user_tag_ids) if specified_user_tags
            items.group(:thread_id).order(:max.sql_function(:date_created).desc,:max.sql_function(:date_updated).desc).map{|t|self[:parent_id => nil, :thread_id => t[:thread_id]].thread} rescue []
          end
        end
        module InstanceMethods
          def rest_associations
            if ! new?
              [ respond_to?(:public_tags) ? :public_tags : nil, respond_to?(:user_tags) ? user_tags_dataset.current_user_dataset : nil].compact
            end
          end
          def new_tags
            [:instance,{:name => 'tags',:url => "#{url}tags", :new_rec => true, :schema => [['number','message_id',RESTRICT_HIDE,id],['text','tags',RESTRICT_REQ]]}]
          end
          def new_user_tags
            [:instance,{:name => 'user_tags',:url => "#{url}user_tags", :new_rec => true, :schema => [['number','user_tags[message_id]',RESTRICT_HIDE,id],['text','user_tags[tags]',RESTRICT_REQ]]}]
          end
          def add_tags(tags,user=nil)
            if respond_to?(:public_tags)
              tags.to_s.split(',').each {|tag| add_public_tag(MR::PublicTag.find_or_create(:tag => tag))}
            else
              add_user_tags(tags,user)
            end
          end
          def add_user_tags(tags,user=nil) #does not conflict with add_user_tag
            user||=$request[:user][:id]
            if user.class==String
              user.split(',').each {|u| add_user_tags(tags,MR::User[:name => u][:id])}
            elsif user.class==Array
              user.each {|u| add_user_tags(tags,u)}
            elsif user.class==Fixnum
              tags.to_s.split(',').each {|tag| add_user_tag(MR::UserTag.find_or_create(:user_id => user, :tag => tag))}
            end
          end
        end
      end
      module Resources
        class User < MJ::BasicUser::Resources::User
        end
        class Admin < User 
          def self.requires_user?;true;end
        end
        class Moderator < User
          def self.requires_user?;true;end
        end
        class PrivateMessage < MJ::BasicMessaging::Resources::PrivateMessage
          attr_accessor :tags
          @actions_get= superclass.actions_get << 'new_tags'
          @section_title='Private Messages'
          @section_name='pms'
          def self.section_navigation
            $request[:user].user_tags.map{|t| [:link,{:url => "/private_message?private_message[tag]=#{t.tag}",:title => t.tag.humanize}]}.unshift(PrivateMessage.reggae_link('new'))
          end
          def rest_schema
            super << [:text, :tags, 0,tags]
          end
          def reply
            r=super
            r.tags=(user_tags_dataset.current_user_dataset.map{|t|t.tag} - RESERVED_PM_TAGS).join(',')
            r
          end
          def after_create
            add_user_tags("inbox,#{tags}",recipients)
            add_user_tags("sent,#{recipients.match(/\b#{author.name}\b/) ? '' : tags}",author_id)
          end
        end
        class Post < MJ::BasicMessaging::Resources::Post
          attr_accessor :tags,:my_tags
          @section_title='Public Posts'
          @section_name='posts'
          def self.section_navigation
            MR::Tag.filter(:user_id => nil).map{|t| [:link,{:url => "/post?post[tag]=#{t.tag}",:title => t.tag.humanize}]}.unshift([:link,{:url => '/post?post[untagged]=true',:title => 'Untagged Messages'}]).unshift(Post.reggae_link('new'))
          end
          @actions_get=(superclass.actions_get << 'new_user_tags') << 'new_tags'
          def rest_schema
            (super << [:text, :tags, 0,tags] ) << [:text, :my_tags, 0,my_tags] 
          end
          def reply
            r=super
            r.tags=self.tags
            r
          end
          def after_create
            add_tags(tags) if tags
            add_user_tags(my_tags) if my_tags
          end
        end
      end
    end
  end
end
