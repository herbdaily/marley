require 'rubygems'
require 'sequel'
require 'digest/sha1'

APP_DIR=File.dirname(__FILE__)
require "#{APP_DIR}/../lib/marley"
require "#{APP_DIR}/../lib/client/jamaica"
DB=Sequel.sqlite("#{APP_DIR}/forum.sqlite3")#,:loggers => [Logger.new($stdout)])

RESERVED_PM_TAGS=['inbox','sent']
RESERVED_POST_TAGS=['announcement']

marley_config({:app_name => 'The Forum',:client => Marley::Client.new({:app_name => 'The Forum'})})

Sequel::Model.plugin :rest_convenience
Sequel::Model.plugin :rest_authorization
Sequel::Model.plugin :validation_helpers
Sequel::Plugins::ValidationHelpers::DEFAULT_OPTIONS.merge!(:presence => {:message => 'is required'})
Sequel::Model.plugin :timestamps, :create => :date_created, :update => :date_updated

joint 'basic_user'
joint 'forum'

