
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
Marley.plugin('rest_authorization').apply(Sequel::Model)
Marley.joint 'user'

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
    end
    class Announcement < Message
      def list(params={})
        filter(params).all
      end
    end
  end
end
Marley.plugin(:current_user_methods).apply(MR::Secret,MR::Announcement)

