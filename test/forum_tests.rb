require 'rubygems'
require 'test/unit'
require "rack/test"
require 'shoulda'
EXAMPLES_DIR=File.dirname(__FILE__) + '/../examples'

`cp #{EXAMPLES_DIR}/empty.sqlite3 #{EXAMPLES_DIR}/forum_test.sqlite3`
ARGV[0]='test'
require "#{EXAMPLES_DIR}/forum.rb"
require "#{EXAMPLES_DIR}/../lib/test_helpers"

class BasicTests < Test::Unit::TestCase
  include Rack::Test::Methods
  include Marley::TestHelpers
  def app
    Marley::Router.new
  end
  context "no user" do
    setup do
      Marley::Resources::User.delete
      @marley_test={:root_uri => '', :resource => 'user'}
    end
    should "return login form with no params" do
      get '/'
      assert_equal 200, last_response.status
    end
    should "return an error when trying to create a user with no params" do
      resp=marley_create(:code => 400 )
      assert_equal "validation", resp.resource_type
      assert_equal ["is required"], resp.properties['name']
    end
    should "return an error when trying to create a user with only a name" do
      resp=marley_create(:code => 400, :'user[name]' => 'asdf')
      assert_equal "validation", resp.resource_type
    end
    should "return an error when password is too short" do
      resp=marley_create(:code => 400, :'user[name]' => 'asdf',:'user[password]' => 'asdfaf')
      assert_equal "validation", resp.resource_type
      assert_equal ["Password must contain at least 8 characters"], resp.properties['password']
    end
    should "return an error when trying to create a user with only a name and password" do
      resp=marley_create(:code => 400, :'user[name]' => 'asdf',:'user[password]' => 'asdfasdf')
      assert_equal "validation", resp.resource_type
      assert_equal ["Passwords do not match"], resp.properties['confirm_password']
    end
    should "allow creation of a new user and disallow user with the same name" do
      marley_create(:'user[name]' => 'asdf',:'user[password]' => 'asdfasdf',:'user[confirm_password]' => 'asdfasdf')
      marley_create(:code => 400,:'user[name]' => 'asdf',:'user[password]' => 'asdfasdf',:'user[confirm_password]' => 'asdfasdf')
    end
    should "not allow access to menus" do
      @marley_test[:resource]='pm_menu'
      marley_read({:code => 401})
      @marley_test[:resource]='post_menu'
      marley_read({:code => 401})
    end
  end
  context "menus for logged in users" do
    setup do
      Marley::Resources::User.delete
      @marley_test={:root_uri => '', :resource => 'user'}
      marley_create(:'user[name]' => 'asdf',:'user[password]' => 'asdfasdf',:'user[confirm_password]' => 'asdfasdf')
      @marley_test={:root_uri => '', :resource => ''}
      authorize 'asdf','asdfasdf'
    end
    should "show main menu" do
      marley_read({})
    end
    should "show PM menu" do
      @marley_test[:resource]='pm_menu'
      marley_read({})
    end
    should "show Posts menu" do
      @marley_test[:resource]='post_menu'
      marley_read({})
    end
  end
end
class MessageTests < Test::Unit::TestCase
  include Rack::Test::Methods
  include Marley::TestHelpers
  def app
    Marley::Router.new
  end
  context "Private Messages" do
    setup do
      Marley::Resources::User.delete
      Marley::Resources::Message.delete
      Marley::Resources::Tag.delete
      DB[:messages_tags].delete
      @marley_test={:root_uri => '', :resource => 'user'}
      marley_create(:'user[name]' => 'user1',:'user[password]' => 'asdfasdf',:'user[confirm_password]' => 'asdfasdf')
      marley_create(:'user[name]' => 'user2',:'user[password]' => 'asdfasdf',:'user[confirm_password]' => 'asdfasdf')
      marley_create(:'user[name]' => 'admin',:'user[password]' => 'asdfasdf',:'user[confirm_password]' => 'asdfasdf')
      Marley::Resources::User[:name => 'admin'].update(:user_type => 'Admin')
      @marley_test[:resource]='private_message'
    end
    context "regular user validations" do
      setup do
        authorize 'user1','asdfasdf'
      end
      should "show PM list" do
        marley_read({})
      end
      should "reject a PM with only recipients" do
        resp=marley_create({:code => 400,:'private_message[recipients]' => 'user2'})
        assert_equal "validation", resp.resource_type
        assert_equal ["is required"], resp.properties['title']
        assert_equal ["is required"], resp.properties['message']
      end
      should "reject a PM to a non-existent user" do
        resp=marley_create({:code => 400,:'private_message[recipients]' => 'asdfasdfasdfasdf',:'private_message[title]' => 'asdf',:'private_message[message]' => 'asdf'})
        assert_equal "validation", resp.resource_type
        assert resp.properties['recipients']
      end
      should "reject a PM from user to user" do
        resp=marley_create({:code => 400,:'private_message[recipients]' => 'user2',:'private_message[title]' => 'asdf',:'private_message[message]' => 'asdf'})
        assert_equal "validation", resp.resource_type
        assert resp.properties['recipients']
      end
      should "accept a PM to admin" do
         marley_create({:'private_message[recipients]' => 'admin',:'private_message[title]' => 'asdf',:'private_message[message]' => 'asdf'})
      end
    end
    context "admin validations" do
      setup do
        authorize 'admin','asdfasdf'
      end
      should "reject a PM with only recipients" do
        resp=marley_create({:code => 400,:'private_message[recipients]' => 'user2'})
        assert_equal "validation", resp.resource_type
        assert_equal ["is required"], resp.properties['title']
        assert_equal ["is required"], resp.properties['message']
      end
      should "accept a PM to user1" do
         marley_create({:'private_message[recipients]' => 'user1',:'private_message[title]' => 'asdf',:'private_message[message]' => 'asdf'})
      end
    end
    context "send message with no tags" do
      setup do
        Marley::Resources::Message.delete
        Marley::Resources::Tag.delete
        DB[:messages_tags].delete
        @marley_test={:root_uri => '', :resource => 'private_message'}
        authorize 'admin','asdfasdf'
        marley_create({:'private_message[recipients]' => 'user1',:'private_message[title]' => 'asdf',:'private_message[message]' => 'asdf'})
      end
      should "show up in PM list of sender and receiver" do
        resp=marley_read({})
        assert_equal 1, resp.length
        authorize 'user1','asdfasdf'
        resp=marley_read({})
        assert_equal 1, resp.length
      end
      should "have sent tag for sender" do
        resp=marley_read({})
        assert_equal 3, resp[0].length
        assert_equal "sent", resp.find_instances('user_tag')[0].schema.tag
      end
      should "have inbox tag for receiver" do
        authorize 'user1','asdfasdf'
        resp=marley_read({})
        assert_equal 3, resp[0].length
        assert_equal "inbox", resp.find_instances('user_tag')[0].schema.tag
      end
    end
    context "send message with 2 tags" do
      setup do
        Marley::Resources::Message.delete
        Marley::Resources::Tag.delete
        DB[:messages_tags].delete
        @marley_test={:root_uri => '', :resource => 'private_message'}
        authorize 'admin','asdfasdf'
        marley_create({:'private_message[recipients]' => 'user1',:'private_message[title]' => 'asdf',:'private_message[message]' => 'asdf', :'private_message[tags]' => 'test,test2'})
      end
      should "have sent tag and both specified tags for sender" do
        resp=marley_read({})
        assert_equal 3, resp[0].find_instances('user_tag').length
      end
      should "have inbox tag and both specified tags for receiver" do
        authorize 'user1','asdfasdf'
        resp=marley_read({})
        assert_equal 3, resp[0].find_instances('user_tag').length
      end
    end
  end
end

