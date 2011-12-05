
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
DB.create_table :secrets do
  primary_key :id
  integer :user_id, :index => true
  text :name
  text :secret
  unique [:name, :user_id]
end
DB.create_table :announcements do
  primary_key :id
  integer :author_id, :index => true
  text :title
  text :announcement
end

Marley.joint 'user'

module Marley
  module Resources
    class Secrets < Sequel::Model
    end
    class Announcements < Sequel::Model
    end
  end
end
Marley.plugin('orm_rest_convenience').apply(MR.constants)
Marley.plugin('rest_authorization').apply(MR.constants)
Marley.plugin(:current_user_methods).apply(MR::Secrets,MR::Announcements)

