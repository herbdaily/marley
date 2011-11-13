require 'rubygems'
require 'test/unit'
require 'shoulda'
require 'sequel'
require 'marley'
require 'marley/test_helpers'

`cp test/empty.sqlite3 test/test.sqlite3`
DB=Sequel.sqlite("test/test.sqlite3")

