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
  text :path, :index => true
  integer :user_id, :index => true
  datetime :date_created, :index => true
  text :message_type, :index => true
  text :title,  :index => true,:null => false
  clob :message
end
DB.create_table :messages_users do
  primary_key :id
  integer :user_id
  integer :message_id
  boolean :read, :index => true
  index [:user_id, :message_id], :unique => true
end
DB.create_table :tags do
  primary_key :id
  integer :user_id,:index => true
  text :tag_type, :index => true
  text :tag,:index => true
end
DB.create_table :messages_tags do
  primary_key :id
  integer :tag_id
  integer :message_id
  index [:tag_id, :message_id], :unique => true
end
DB.create_table :topics_tags do
  primary_key :id
  integer :tag_id
  integer :topic_id
  index [:tag_id, :topic_id], :unique => true
end
 

Marley.config(:app_name => 'Forum',:client => Marley::Client.new(:app_name => 'Forum'))
Marley.joint('forum')
#require 'test/forum_load.rb'
