require 'rubygems'
require 'minitest/autorun'
require 'marley.rb'
require 'marley/test_helpers'
require 'spec/hello.rb'
require 'spec/example_plugin.rb'

describe MR::Hello do
  before do
    @client=Marley::TestClient.new(:resource_name => 'hello')
    @plugin=Marley.plugin('example_plugin')
  end
  it "without example plugin" do
    assert_equal(1,1)
    MR.constants.must_equal(["Hello"])
    @client.read.must_equal("\"Hello World!\"")
    @client.create({}, :code => 404).must_equal([:error, {:description=>"Not Found", :error_type=>"routing", :error_details=>nil}])
  end
  it "with example plugin" do
    @plugin.apply('Hello').must_equal(nil)
    @client.create({}).must_equal(" world")
    @client.create({},:method => 'howdy').must_equal("howdy world")
  end
end
