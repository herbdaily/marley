require 'rubygems'
require 'minitest/autorun'
require 'spec/user_joint.rb'

describe MP::User do
  before do
    MR::User.delete
    MR::Message.delete
    DB[:SQLITE_SEQUENCE].delete  #kinda hate this but it seems necessary for the moment
    @client=Marley::TestClient.new(:resource_name => 'user')
    @user=@client.read({},:method => 'new')
  end
  it "works" do
    true
  end
end



