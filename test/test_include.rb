require 'rubygems'
require 'test/unit'
require 'shoulda'
require 'sequel'
require 'marley'
require 'marley/test_helpers'

`cp test/empty.sqlite3 test/test.sqlite3`
DB=Sequel.sqlite("test/test.sqlite3")

RESERVED_PM_TAGS=['inbox','sent']
RESERVED_POST_TAGS=['announcement']

Marley.joint 'tagged_messaging'
Marley.joint 'basic_menu_system'

