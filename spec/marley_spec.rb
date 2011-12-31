require 'rubygems'
require 'minitest/autorun'
require 'spec/hello.rb'


describe MR::Hello do
  before do
     @client=Marley::TestClient.new({:resource_name => 'hello'}) 
  end
  describe "when requested with no args" do
    it "should respond with 'Hello World!'" do
      @client.read.must_equal "\"Hello World!\""
    end
  end
  describe "when requested with a who arg" do
    it "should respond with 'Hello [arg]!'" do
      @client.read({:who => 'Dolly'}).must_equal "\"Hello Dolly!\""
    end
  end
end

