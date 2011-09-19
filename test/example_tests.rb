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
  def test_new_user_errors
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
  end
#  def test_new_users
#    @req.opts.merge!(:uri => '/user/',:expected_status => 200)
#    resp=@req.post({:params => 'user[name]=asdf&user[password]=asdfasdf&user[confirm_password]=asdfasdf'})
#    resp=@req.post({:params => 'user[name]=asdf&user[password]=asdfasdf&user[confirm_password]=asdfasdf',:expected_status => 500})
#    assert_equal "validation", resp[0]
#    assert_equal "name", resp[1].keys[0]
#  end
end
