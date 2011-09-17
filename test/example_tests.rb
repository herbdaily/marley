require 'test/unit'
EXAMPLES_DIR=File.dirname(__FILE__) + '/../examples'

`cp #{EXAMPLES_DIR}/empty.sqlite3 #{EXAMPLES_DIR}/forum_test.sqlite3`
ARGV[0]='test'
require "#{EXAMPLES_DIR}/simple_forum.rb"
require 'mock_request'

class ExampleTests < Test::Unit::TestCase
  def setup
    @req=Marley::MockRequest.new(Marley::Router.new)
  end
  def test_return_client
    @req.get
    @req.get({:uri => '/asdf',:expected_status => 500})
  end
  def test_user_rest
    @req.opts.merge!(:uri => '/user/',:expected_status => 500)
    resp=@req.post
    assert_equal "validation", resp[0]
    assert_equal "name", resp[1].keys[0]
    resp=@req.post({:params => 'user[name]=asdf'})
    assert_equal "validation", resp[0]
    assert_equal 'password', resp[1].keys[0]
    resp=@req.post({:params => 'user[name]=asdf&user[password]=asdfasdf'})
    assert_equal "validation", resp[0]
    assert_equal 'confirm_password', resp[1].keys[0]
    resp=@req.post({:params => 'user[name]=asdf&user[password]=asdfasdf&user[confirm_password]=asdfasdf',:expected_status => 200})
  end
end
