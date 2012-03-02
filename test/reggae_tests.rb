require 'rubygems'
require 'detest'
include Detest

require 'marley/utils.rb'
require 'marley/reggae.rb'

D 'Generate' do
  T {@instance=Marley::ReggaeInstance.new({:name => 'foo',:schema => []})==[:instance, {:schema=>[], :name=>"foo"}, []]}

  T {(@link=Marley::ReggaeLink.new({:url => '/', :title => 'asdf'}))==[:link, {:url=>"/", :title=>"asdf"}, []]}
  T {@link.update(:url => '/asdf/')==[:link, {:url=>"/asdf/", :title=>"asdf"}, []]}

end
D 'parse' do
end
