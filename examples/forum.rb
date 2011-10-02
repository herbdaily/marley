require 'rubygems'
require 'sequel'
require 'digest/sha1'

$: << "#{File.dirname(__FILE__)}/../lib/"

APP_DIR=File.dirname(__FILE__)
require "marley"
require "client/jamaica"
#need to automate the following somehow but can't think of anything that isn't ugly ATM
DB=Sequel.sqlite("#{APP_DIR}/forum#{ARGV[0]=='test' ? '_test' : ''}.sqlite3")#,:loggers => [Logger.new($stdout)])

RESERVED_PM_TAGS=['inbox','sent']
RESERVED_POST_TAGS=['announcement']

marley_config({:app_name => 'The Forum',:client => Marley::Client.new({:app_name => 'The Forum'})})

Sequel::Model.plugin :rest_convenience
Sequel::Model.plugin :rest_authorization
Sequel::Model.plugin :validation_helpers
Sequel::Plugins::ValidationHelpers::DEFAULT_OPTIONS.merge!(:presence => {:message => 'is required'})
Sequel::Model.plugin :timestamps, :create => :date_created, :update => :date_updated

joint 'basic_user'
joint 'basic_menu_system'
joint 'basic_messaging'
joint 'tagging'
module Marley
  module Resources
    class MainMenu < Menu
      def self.requires_user?
        $request[:path].to_a!=[]
      end
      def initialize
        @name='main'
        if $request[:user].new?
          u=$request[:user].to_a
          u[1].merge!({:description => 'If you don\'t already have an account, please create one here:'})
          @title="Welcome to #{$request[:opts][:app_name]}"
          @description='Login or signup here.'
          @items=[LOGIN_FORM,u]
        else
          @title = 'Forum Main Menu'
          @description="Welcome to #{$request[:opts][:app_name]}, #{$request[:user].name}"
          @items=[ [:uri,{:url => '/pm_menu',:title => 'Private Messages'}], [:uri,{:url => '/post_menu',:title => 'Posts'}] ]
        end
      end
    end
    class PostMenu < Menu
      def initialize
        @name='posts'
        @title='Posts'
        @items=Tag.filter(:user_id => nil).map{|t| [:uri,{:url => "/post?post[tag]=#{t.tag}",:title => t.tag.humanize}]}.unshift([:uri,{:url => '/post?post[untagged]=true',:title => 'Untagged Messages'}]).unshift(Post.json_uri('new')) 
      end
    end
    class PmMenu < Menu
      def initialize
        @name='pm'
        @title='Private Messages'
        @items=$request[:user].user_tags.map{|t| [:uri,{:url => "/private_message?private_message[tag]=#{t.tag}",:title => t.tag.humanize}]}.unshift(PrivateMessage.json_uri('new'))
      end
    end
    class User < BasicUser 
      def private_messages(params={})
        params||={}
        if specified_tags=params.delete(:tags)
          tag_ids=user_tags_dataset.filter(:tag => specified_tags.split(/\s*,\s*/)).select(:id)
        end
        threads=PrivateMessage.filter("author_id=#{$request[:user][:id]} or recipients like('%#{$request[:user][:name]}%')".lit)
        threads=threads.filter(params)
        if specified_tags
          threads=threads.join(:message_tags,:message_id => :id).filter(:tag_id => tag_ids)
        end
        threads.group(:thread_id).order(:max.sql_function(:date_created).desc,:max.sql_function(:date_updated).desc).map{|t|PrivateMessage[:parent_id => nil, :thread_id => t[:thread_id]].thread}
      end
      def posts(params={})
        params||={}
        if specified_tags=params.delete(:tags)
          tag_ids=public_tags_dataset.filter(:tag => specified_tags.split(/\s*,\s*/)).select(:id)
        end
        if specified_user_tags=params.delete(:user_tags)
          user_tag_ids=user_tags_dataset.filter(:tag => specified_tags.split(/\s*,\s*/)).select(:id)
        end
        threads=Post.filter(params)
        if specified_tags
          threads=threads.join(:message_tags,:message_id => :id).filter(:tag_id => tag_ids)
          if specified_user_tags
            threads=threads.or(:tag_id => user_tag_ids)
          end
        elsif specified_user_tags
          threads=threads.join(:message_tags,:message_id => :id).filter(:tag_id => user_tag_ids)
        end
        threads.group(:thread_id).order(:max.sql_function(:date_created).desc,:max.sql_function(:date_updated).desc).map{|t|Post[:parent_id => nil, :thread_id => t[:thread_id]].thread}
      end
    end
    class Admin < User 
      def self.requires_user?;true;end
    end
    class Moderator < User
      def self.requires_user?;true;end
    end
  end
  message_tagging('User')
end
