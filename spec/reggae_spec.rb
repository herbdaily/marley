require 'rubygems'
require 'minitest/autorun'
require 'marley.rb'
require 'marley/reggae.rb'

describe Marley::Reggae do
  describe "as a parser" do
    it "leaves non-Reggae arrays as is" do
      Marley::Reggae.new([]).must_equal( [])
      Marley::Reggae.new(['asdf','ssss']).must_equal( ["asdf", "ssss"])
      Marley::Reggae.new(['asdf','ssss']).class.must_equal(Marley::Reggae)
      Marley::Reggae.new(['asdf',{}]).to_resource.must_equal(["asdf", {}])
      Marley::Reggae.new(['asdf',{}]).to_resource.class.must_equal(Marley::Reggae)
    end
    describe "given a simple Reggae Resource" do
      it "returns a ReggaeResource instance" do
        Marley::Reggae.new(['resource',{}]).to_resource.class.must_equal(Marley::ReggaeResource)
        Marley::Reggae.get_resource(['resource',{}]).class.must_equal(Marley::ReggaeResource)
      end
    end
    describe "given a Reggae Section" do
      it "returns a ReggaeSection instance" do
        (@section=Marley::Reggae.new([:section, {}]).to_resource).must_equal([:section, {}])
        @section.properties.must_equal({})
      end
      describe "with a title" do
        it "returns a ReggaeSection instance with a title" do
          (@section=Marley::Reggae.new([:section, {:title => 'asdf'}]).to_resource).must_equal([:section, {:title=>"asdf"}])
          @section.title.must_equal("asdf")
          @section.properties.must_equal({:title=>"asdf"})
        end
      end
    end
  end
  describe "as a generator given an instance" do
    it "returns the correct array" do
      Marley::ReggaeInstance.new({:name => 'foo',:schema => []}).must_equal([:instance, {:schema=>[], :name=>"foo"}, []])
    end
  end
end
