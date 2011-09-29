require 'rubygems'
require 'test/unit'
require "rack/test"
EXAMPLES_DIR=File.dirname(__FILE__) + '/../examples'

`cp #{EXAMPLES_DIR}/empty.sqlite3 #{EXAMPLES_DIR}/forum_test.sqlite3`
ARGV[0]='test'
require "#{EXAMPLES_DIR}/forum.rb"
require "#{EXAMPLES_DIR}/../lib/test_helpers"

class MessageTests < Test::Unit::TestCase
  include Rack::Test::Methods
  include Marley::TestHelpers
  def setup
    Marley::Resources::User.delete
    Marley::Resources::Message.delete
    Marley::Resources::Tag.delete
    @marley_test={:root_uri => '', :resource => 'user'}
    marley_create(:'user[name]' => 'user1',:'user[password]' => 'asdfasdf',:'user[confirm_password]' => 'asdfasdf')
    marley_create(:'user[name]' => 'user2',:'user[password]' => 'asdfasdf',:'user[confirm_password]' => 'asdfasdf')
    marley_create(:'user[name]' => 'user3',:'user[password]' => 'asdfasdf',:'user[confirm_password]' => 'asdfasdf')
    marley_create(:'user[name]' => 'user4',:'user[password]' => 'asdfasdf',:'user[confirm_password]' => 'asdfasdf')
    marley_create(:'user[name]' => 'user5',:'user[password]' => 'asdfasdf',:'user[confirm_password]' => 'asdfasdf')
  end
  def app
    Marley::Router.new
  end
  def test_private_message
    @marley_test={:root_uri => '', :resource => 'private_message'}
    authorize 'user1','asdfasdf'
    marley_read
    #resp=marley_create({:code => 400,:'private_message[recipients]' => 'user2'})
  end
  def test_posts
    @marley_test={:root_uri => '', :resource => 'post'}
    marley_read({:code => 401})
    authorize 'user1','asdfasdf'
    #marley_read
  end

end
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
    @marley_test[:resource]='pm_menu'
    marley_read({:code => 401})
    @marley_test[:resource]='post_menu'
    marley_read({:code => 401})

    authorize 'asdf','asdfasdf'
    @marley_test[:resource]=''
    marley_read({})
    @marley_test[:resource]='pm_menu'
    marley_read({})
    @marley_test[:resource]='post_menu'
  end
end
