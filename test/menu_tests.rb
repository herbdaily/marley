

class MenuTests < Test::Unit::TestCase
  def setup
    Marley::Resources::User.delete
    @client=Marley::TestClient.new(:resource_name => 'user',:code => 400)
  end
  should 'work' do
    assert true
  end
end
