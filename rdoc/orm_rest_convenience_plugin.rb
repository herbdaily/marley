
require 'rubygems'
require 'sequel'
require 'marley'
require 'marley/test_helpers'

DB=Sequel.sqlite('')
DB.create_table :users do
  primary_key :id
  text :name
  text :user_type
  text :pw_hash
  text :description
end

module Marley
  module Resources
  end
end
