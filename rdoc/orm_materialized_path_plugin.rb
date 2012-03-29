
require 'marley'
require 'marley/test_helpers'

DB=Sequel.sqlite('')
DB.create_table :trees do
  primary_key :id
  text :name, :index => true
  text :path, :index => true
end

Marley.plugin('orm_rest_convenience').apply(Sequel::Model)
Marley.config {}
module Marley
  module Resources
    class Tree < Sequel::Model
      Marley.plugin('orm_materialized_path').apply(self)
    end
  end
end

