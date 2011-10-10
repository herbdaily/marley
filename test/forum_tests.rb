require 'rubygems'
require 'test/unit'
require 'shoulda'
EXAMPLES_DIR=File.dirname(__FILE__) + '/../examples'

`cp #{EXAMPLES_DIR}/empty.sqlite3 #{EXAMPLES_DIR}/forum_test.sqlite3`
ARGV[0]='test'
require "#{EXAMPLES_DIR}/forum.rb"
require "#{EXAMPLES_DIR}/../lib/test_helpers"

class BasicTests < Test::Unit::TestCase
  include Marley::TestHelpers
  context "no user" do
    setup do
      Marley::Resources::User.delete
      @mock=Marley::TestClient.new(:resource_name => 'user',:code => 400)
    end
    should "return login form with no params" do
      assert @mock.read({},{:resource_name => '',:code => 200})
    end
    should "return an error when trying to create a user with no params" do
      assert resp=@mock.create
      assert_equal "validation", resp.resource_type
      assert_equal ["is required"], resp.properties['name']
    end
    should "return an error when trying to create a user with only a name" do
      resp=@mock.create({:'user[name]' => 'asdf'})
      assert_equal "validation", resp.resource_type
    end
    should "return an error when password is too short" do
      resp=@mock.create({:'user[name]' => 'asdf',:'user[password]' => 'asdfaf'})
      assert_equal "validation", resp.resource_type
      assert_equal ["Password must contain at least 8 characters"], resp.properties['password']
    end
    should "return an error when trying to create a user with only a name and password" do
      resp=@mock.create(:'user[name]' => 'asdf',:'user[password]' => 'asdfasdf')
      assert_equal "validation", resp.resource_type
      assert_equal ["Passwords do not match"], resp.properties['confirm_password']
    end
    should "allow creation of a new user and disallow user with the same name" do
      @mock.code=200
      @mock.create(:'user[name]' => 'asdf',:'user[password]' => 'asdfasdf',:'user[confirm_password]' => 'asdfasdf')
      @mock.create(:'user[name]' => 'asdf',:'user[password]' => 'asdfasdf',:'user[confirm_password]' => 'asdfasdf')
    end
    should "not allow access to menus" do
      @mock.read({:resource_name =>'pm_menu'},{:code => 401})
      @mock.read({:resource_name =>'post_menu'},{:code => 401})
    end
  end
end
