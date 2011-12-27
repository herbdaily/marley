require 'rubygems'
require 'sequel'
require 'marley'
require 'marley/test_helpers'

DB=Sequel.sqlite('')
DB.create_table :users do
  primary_key :id
  text :name, :unique => true
  text :user_type, :index => true
  text :pw_hash
  datetime :date_created
  text :description
end
DB.create_table :messages do
  primary_key :id
  integer :user_id, :index => true
  text :message_type, :index => true
  text :title,  :index => true,:null => false
  text :content
end
DB.create_table :messages_users do
  primary_key :id
  integer :user_id
  integer :message_id
  boolean :read, :index => true
  index [:user_id, :message_id], :unique => true
end

Sequel::Model.plugin :validation_helpers
Marley.plugin('orm_rest_convenience').apply(Sequel::Model)
Marley.joint 'user'
Marley.plugin('current_user_methods').apply(Sequel::Model)
Marley.joint 'messages'
