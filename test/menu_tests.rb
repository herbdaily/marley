

Marley.joint 'tagged_messaging'
Marley.joint 'basic_menu_system'
class MenuTests < Test::Unit::TestCase
  def setup
    Marley::Resources::User.delete
    @client=Marley::TestClient.new(:resource_name => 'user',:code => 400)
  end
end
