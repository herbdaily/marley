
Marley.joint 'basic_user'
Marley.joint 'basic_menu_system'

class UserTests < Test::Unit::TestCase
  def setup
    Marley::Resources::User.delete
    @client=Marley::TestClient.new(:resource_name => 'user',:code => 400)
  end
  should "return login form with no params" do
    assert @client.read({},{:resource_name => '',:code => 200})
  end
  should "not allow access to menus, private messages, or posts" do
    assert @client.read({:resource_name =>'pm_menu'},{:code => 401})
    assert @client.read({:resource_name =>'post_menu'},{:code => 401})
    assert @client.read({:resource_name =>'private_message'},{:code => 401})
    assert @client.read({:resource_name =>'post'},{:code => 401})
  end
  should "validate new user properly" do
    assert resp=@client.create
    assert_equal :error, resp.resource_type
    assert_equal "validation", resp.error_type
    assert_equal ["is required"], resp.error_details[:name]
    resp=@client.create({:'user[name]' => 'asdf'})
    assert_equal :error, resp.resource_type
    assert_equal "validation", resp.error_type
    resp=@client.create({:'user[name]' => 'asdf',:'user[password]' => 'asdfaf'})
    assert_equal :error, resp.resource_type
    assert_equal "validation", resp.error_type
    assert_equal ["Password must contain at least 8 characters"], resp.error_details[:password]
    resp=@client.create(:'user[name]' => 'asdf',:'user[password]' => 'asdfasdf')
    assert_equal :error, resp.resource_type
    assert_equal "validation", resp.error_type
    assert_equal ["Passwords do not match"], resp.error_details[:confirm_password]
  end
  should "allow creation of a new user and disallow user with the same name" do
    @client.code=200
    @client.create(:'user[name]' => 'asdf',:'user[password]' => 'asdfasdf',:'user[confirm_password]' => 'asdfasdf')
    assert @client.create({:'user[name]' => 'asdf',:'user[password]' => 'asdfasdf',:'user[confirm_password]' => 'asdfasdf'},{:code => 400})
  end
  context "existing user logged in" do
    setup do
      @client.code=201
      assert @client.create(:'user[name]' => 'user1',:'user[password]' => 'asdfasdf',:'user[confirm_password]' => 'asdfasdf')
      assert @client.create(:'user[name]' => 'user2',:'user[password]' => 'asdfasdf',:'user[confirm_password]' => 'asdfasdf')
      @client.code=200
      @client.auth=['user1','asdfasdf']
    end
    should "show sinlge menu item" do
      menu= @client.read({},:resource_name => '')
      assert_equal ["User Info"], menu.navigation.map{|n| n.title}
    end
    should "allow viewing and changing of user columns with proper validation" do
      @client.instance_id=1
      assert user=@client.read({})
      params=user.to_params
      assert @client.update(params,{:code => 204})
      assert err=@client.update(params.update('user[password]' => 'zxcvzxcv'),{:code => 400})
      assert_equal :error, err.resource_type
      assert_equal "validation", err.error_type
      assert @client.update(params.update('user[password]' => 'zxcvzxcv','user[confirm_password]' => 'zxcvzxcv', 'user[old_password]' => 'asdfasdf'),:code => 204)
      assert @client.read({},:code => 401)
      @client.auth=['user1','zxcvzxcv']
      assert @client.read({})
      @client.instance_id=2
      assert @client.update(params.update('user[password]' => 'zxcvzxcv','user[confirm_password]' => 'zxcvzxcv', 'user[old_password]' => 'asdfasdf'),:code => 403)
    end
  end
end
