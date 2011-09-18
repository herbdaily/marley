require 'rubygems'
require 'test/unit'
require "rack/test"
require '/home/user/rack-test-rest/lib/rack-test-rest'
EXAMPLES_DIR=File.dirname(__FILE__) + '/../examples'

`cp #{EXAMPLES_DIR}/empty.sqlite3 #{EXAMPLES_DIR}/forum_test.sqlite3`
ARGV[0]='test'
require "#{EXAMPLES_DIR}/simple_forum.rb"

class UserTests < Test::Unit::TestCase
  include Rack::Test::Methods
  include Rack::Test::Rest
  def setup
    @rack_test_rest={:root_uri => '/', :resource => 'user'}
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
#  def test_new_user_errors
#    resp=@req.post
#    assert_equal "validation", resp[0]
#    assert_equal "name", resp[1].keys[0]
#    resp=@req.post({:params => 'user[name]=asdf'})
#    assert_equal "validation", resp[0]
#    assert_equal 'password', resp[1].keys[0]
#    resp=@req.post({:params => 'user[name]=asdf&user[password]=asdfasdf'})
#    assert_equal "validation", resp[0]
#    assert_equal 'confirm_password', resp[1].keys[0]
#  end
#  def test_new_users
#    @req.opts.merge!(:uri => '/user/',:expected_status => 200)
#    resp=@req.post({:params => 'user[name]=asdf&user[password]=asdfasdf&user[confirm_password]=asdfasdf'})
#    resp=@req.post({:params => 'user[name]=asdf&user[password]=asdfasdf&user[confirm_password]=asdfasdf',:expected_status => 500})
#    assert_equal "validation", resp[0]
#    assert_equal "name", resp[1].keys[0]
#  end
end
