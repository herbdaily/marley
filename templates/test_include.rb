require 'marley'
require 'marley/test_helpers'

DB=Sequel.sqlite('')
DB.create_table :foo do
  primary_key :id
  text :name, :unique => true
end
Marley.config {}
module Marley
  module Resources
  end
end
