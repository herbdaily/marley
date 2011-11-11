TEST_DIR=File.dirname(__FILE__)
$: << "#{TEST_DIR}/../lib"
require 'rubygems'
require 'test/unit'
require 'shoulda'
require 'sequel'
require 'marley'
require 'marley/test_helpers'

`cp test/empty.sqlite3 test/test.sqlite3`
DB=Sequel.sqlite("test/test.sqlite3")

require 'test/user_tests'
