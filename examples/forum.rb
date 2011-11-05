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


Marley.joint 'tagged_messaging'
Marley.joint 'basic_menu_system'
module Marley
  module Resources
    class MainMenu < Menu
      def self.requires_user?
        $request[:path].to_a !=[]
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
          @items=[ [:link,{:url => $request[:user].url,:title => 'Account'}],[:link,{:url => '/pm_menu',:title => 'Private Messages'}], [:link,{:url => '/post_menu',:title => 'Posts'}] ]
        end
      end
    end
    class PostMenu < Menu
      def initialize
        @name='posts'
        @title='Posts'
        @items=Tag.filter(:user_id => nil).map{|t| [:link,{:url => "/post?post[tag]=#{t.tag}",:title => t.tag.humanize}]}.unshift([:link,{:url => '/post?post[untagged]=true',:title => 'Untagged Messages'}]).unshift(Post.reggae_link('new')) 
      end
    end
    class PmMenu < Menu
      def initialize
        @name='pm'
        @title='Private Messages'
        @items=$request[:user].user_tags.map{|t| [:link,{:url => "/private_message?private_message[tag]=#{t.tag}",:title => t.tag.humanize}]}.unshift(PrivateMessage.reggae_link('new'))
      end
    end
  end
end
