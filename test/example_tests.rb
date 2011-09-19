require 'rubygems'
require 'test/unit'
require "rack/test"
EXAMPLES_DIR=File.dirname(__FILE__) + '/../examples'

`cp #{EXAMPLES_DIR}/empty.sqlite3 #{EXAMPLES_DIR}/forum_test.sqlite3`
ARGV[0]='test'
require "#{EXAMPLES_DIR}/simple_forum.rb"
require "#{EXAMPLES_DIR}/../lib/test_helpers"

class UserTests < Test::Unit::TestCase
  include Rack::Test::Methods
  include Marley::TestHelpers
  def setup
    Marley::Resources::User.delete
    @marley_test={:root_uri => '', :resource => 'user'}
  end
  def app
    Marley::Router.new
  end
  def test_return_client
    get '/'
    assert_equal 200, last_response.status
    get '/asdf'
    assert_equal 500, last_response.status
  end
  def test_new_users
    resp=marley_create(:code => 400 )
    assert_equal "validation", resp[0]
    assert_equal ["is required"], resp[1]['name']
    resp=marley_create(:code => 400, :'user[name]' => 'asdf')
    assert_equal "validation", resp[0]
    resp=marley_create(:code => 400, :'user[name]' => 'asdf',:'user[password]' => 'asdfaf')
    assert_equal "validation", resp[0]
    assert_equal ["Password must contain at least 8 characters"], resp[1]['password']
    resp=marley_create(:code => 400, :'user[name]' => 'asdf',:'user[password]' => 'asdfasdf')
    assert_equal "validation", resp[0]
    assert_equal ["Passwords do not match"], resp[1]['confirm_password']
    marley_create(:'user[name]' => 'asdf',:'user[password]' => 'asdfasdf',:'user[confirm_password]' => 'asdfasdf')
    marley_create(:code => 400,:'user[name]' => 'asdf',:'user[password]' => 'asdfasdf',:'user[confirm_password]' => 'asdfasdf')
  end
  def test_auth
    marley_create(:'user[name]' => 'asdf',:'user[password]' => 'asdfasdf',:'user[confirm_password]' => 'asdfasdf')
    authorize 'asdf','asdfasdf'
    @marley_test[:resource]=''
    marley_read({})
    @marley_test[:resource]='menu/private_message'
    marley_read({})
    @marley_test[:resource]='menu/public_message'
    marley_read({})
  end
end
