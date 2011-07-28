require 'test/unit'
EXAMPLES_DIR=File.dirname(__FILE__) + '/../examples'

`cp #{EXAMPLES_DIR}/empty.sqlite3 #{EXAMPLES_DIR}/forum.sqlite3`
require "#{EXAMPLES_DIR}/simple_forum.rb"
R=Marley::Resources

class ExampleTests < Test::Unit::TestCase
  # def setup
  # end

  # def teardown
  # end
  def test_user_models
    assert_kind_of R::User, R::User.new
    new_user=R::User.new(:name => 'foo',:password => 'asdfasdf', :confirm_password => '')
    assert_raises(Sequel::ValidationFailed){new_user.save}
    new_user.confirm_password='asdfasdf'
    assert_nothing_raised {new_user.save}
    assert_equal new_user, R::User[1]

    new_user=R::User.new(:name => 'foo',:password => 'asdfasdf', :confirm_password => 'asdfasdf')
    new_user.save rescue err=$!
    assert_kind_of Sequel::ValidationFailed, err
    assert_equal 2, err.errors.count
    assert_kind_of String, err.errors[[:name]][0]
    assert_kind_of String, err.errors[[:email]][0]

    new_user.name='bar'
    new_user.save rescue err=$!
    assert_kind_of Sequel::ValidationFailed, err
    assert_equal 1, err.errors.count
    assert_kind_of String, err.errors[[:email]][0]

    new_user.email='bar'
    assert_nothing_raised {new_user.save}
    assert_equal new_user, R::User[2]

    admin_try=R::User.new(:name => 'admin_try',:password => 'asdfasdf', :confirm_password => 'asdfasdf', :user_type => 'Admin')
    assert_raises(Sequel::ValidationFailed) {admin_try.save}
  end
  def test_user_rest
    r=Rack::MockRequest.new(Marley::Router.new)
    assert_equal 200, r.get('/').status
    assert_equal 500, r.get('/asdf').status

  end
end
