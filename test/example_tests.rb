require 'test/unit'
EXAMPLES_DIR=File.dirname(__FILE__) + '/../examples'

`cp #{EXAMPLES_DIR}/empty.sqlite3 #{EXAMPLES_DIR}/forum_test.sqlite3`
ARGV[0]='test'
require "#{EXAMPLES_DIR}/simple_forum.rb"
require 'smoke'

class ExampleTests < Test::Unit::TestCase
  include Marley::Smoke
  def setup
    @req=Rack::MockRequest.new(Marley::Router.new)
  end
  def test_return_client
    smoke
    assert_equal 200, @req.get('/').status
    assert_equal 500, @req.get('/asdf').status
  end
  def test_user_rest
    resp=@req.post('/user/',:params => 'user=')
    assert_equal 500, resp.status
    json=JSON.parse(resp.body)
    assert_equal "validation", json[0]
    assert_equal "name", json[1].keys[0]
    resp=@req.post('/user/',:params => 'user[name]=asdf')
    assert_equal 500, resp.status
    json=JSON.parse(resp.body)
    assert_equal "validation", json[0]
    assert_equal 'password', json[1].keys[0]
    resp=@req.post('/user/',:params => 'user[name]=asdf&user[password]=asdfasdf&user[confirm_password]=asdfasdf')
    assert_equal 200, resp.status
  end
end
