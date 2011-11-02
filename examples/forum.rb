require 'rubygems'
require 'sequel'
require 'digest/sha1'

$: << "#{File.dirname(__FILE__)}/../lib/"

APP_DIR=File.dirname(__FILE__)
require "marley"
require "client/jamaica"
#need to automate the following somehow but can't think of anything that isn't ugly ATM
DB=Sequel.sqlite("#{APP_DIR}/forum#{ENV["MARLEY_TESTING"] ? '_test' : ''}.sqlite3")#,:loggers => [Logger.new($stdout)])

RESERVED_PM_TAGS=['inbox','sent']
RESERVED_POST_TAGS=['announcement']

Marley.config({:app_name => 'The Forum',:client => Marley::Client.new({:app_name => 'The Forum'})})

Sequel::Model.plugin :rest_convenience
Sequel::Model.plugin :rest_authorization
Sequel::Model.plugin :validation_helpers
Sequel::Plugins::ValidationHelpers::DEFAULT_OPTIONS.merge!(:presence => {:message => 'is required'})
Sequel::Model.plugin :timestamps, :create => :date_created, :update => :date_updated

Marley.joint 'basic_user',{:import => []}
Marley.joint 'basic_menu_system'
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
          @items=[ [:uri,{:url => $request[:user].url,:title => 'Account'}],[:uri,{:url => '/pm_menu',:title => 'Private Messages'}], [:uri,{:url => '/post_menu',:title => 'Posts'}] ]
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
    class User < Marley::Joints::BasicUser::Resources::User
    end
    class Admin < User 
      def self.requires_user?;true;end
    end
    class Moderator < User
      def self.requires_user?;true;end
    end
  end
end
Marley.joint 'basic_messaging',{:tagging => true, :tagging_user_class => 'User'}
