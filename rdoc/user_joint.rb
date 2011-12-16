
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
  text :description
end
DB.create_table :messages do
  primary_key :id
  integer :user_id, :index => true
  text :message_type, :index => true
  text :name,  :index => true,:null => false
  text :message
end

Sequel::Model.plugin :validation_helpers
Marley.plugin('orm_rest_convenience').apply(Sequel::Model)
Marley.joint 'user'
Marley.plugin('current_user_methods').apply(Sequel::Model)

module Marley
  module Resources
    class Message < Sequel::Model
      sti
      def validate
        super
        validates_presence [:name]
      end
    end
    class Secret < Message
      User.join_to(self)
      def self.list_dataset
        current_user_ds
      end
    end
    class Announcement < Message
      def instance_actions(parent_instance=nil)
        {:delete => self.url} if current_user_role=='owner' && ! self.new?
      end
    end
  end
end

