
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
  text :email
  date :birthday
  datetime :date_created
  text :description
end
DB.create_table :messages do
  primary_key :id
  integer :user_id, :index => true
  text :message_type, :index => true
  text :name,  :index => true,:null => false
  text :message
end

Marley.plugin('orm_rest_convenience').apply(Sequel::Model)
Marley.joint 'user'
Marley.plugin('current_user_methods').apply(Sequel::Model)

module Marley
  module Resources
    class Admin < User
      def self.requires_user?; true;end
    end
    class Message < Sequel::Model
      sti # sets single_table_inheritance plugin
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
      ro_cols![MP::CURRENT_USER_ROLE_PROC]={'reader' => [/.*/]}
      def current_user_role
        super || 'reader' unless User.current_user.new?
      end
      def actions(parent_instance=nil)
        if current_user_role=='owner' && ! self.new?
          {:delete => self.url}.update(super ? super : {})
        else
          super
        end
      end
    end
  end
end

