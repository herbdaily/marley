require 'rubygems'
require 'sequel'
require 'digest/sha1'

$: << "#{File.dirname(__FILE__)}/../lib/"

Sequel::Plugins::ValidationHelpers::DEFAULT_OPTIONS.merge!(:presence => {:message => 'is required'})
Sequel::Model.plugin :timestamps, :create => :date_created, :update => :date_updated

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
