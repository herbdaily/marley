
require 'marley'
require 'marley/test_helpers'

DB=Sequel.sqlite('')
DB.create_table :tree do
  primary_key :id
  text :name, :unique => true
  text :path, :unique => true
end

Marley.config {}
module Marley
  module Resources
    class Tree < Sequel::Model
      Marley.plugin('orm_rest_convenience').apply(self)
      Marley.plugin('orm_manifest_path').apply(self)
    end
  end
end

