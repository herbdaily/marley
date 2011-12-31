
require 'rubygems'
require 'sequel'
require 'marley'
require 'marley/test_helpers'

DB=Sequel.sqlite('')
DB.create_table :users do
  primary_key :id
  text :name,:unique => true, :null => false
  text :password, :null => false
  text :description, :null => false
end

Marley.config(:http_auth => false)
module Marley
  module Resources
    class User < Sequel::Model
      def validate
        validates_presence :name
        validates_unique :name
        validates_presence :description
        validates_presence :password
      end
    end
  end
end
  Marley.plugin('orm_rest_convenience').apply('User')
