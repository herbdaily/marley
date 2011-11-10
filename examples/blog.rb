require 'rubygems'
require 'sequel'
require 'digest/sha1'

$: << "#{File.dirname(__FILE__)}/../lib/"

APP_DIR=File.dirname(__FILE__)
require "marley"
require "client/jamaica"
#need to automate the following somehow but can't think of anything that isn't ugly ATM
DB=Sequel.sqlite("#{APP_DIR}/forum#{ENV["MARLEY_TESTING"] ? '_test' : ''}.sqlite3")#,:loggers => [Logger.new($stdout)])

Marley.config({:app_name => 'The Forum',:client => Marley::Client.new({:app_name => 'The Forum'})})

Marley.joint 'tagged_messaging', {:resources => ['user','admin']}
Marley.joint 'basic_menu_system'

module Marley
  module Resources
    class Author < User
    end
    class Post < MJ::TaggedMessaging::Resources::Post
    end
  end
end
