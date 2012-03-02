require 'rubygems'
require 'detest'
include Detest

require 'marley/utils.rb'
require 'marley/reggae.rb'

D 'Generate' do
  T {(@instance=Marley::ReggaeInstance.new({:name => 'foo',:schema => []}))==[:instance, {:schema=>[], :name=>"foo"}, []]}

  T {(@link=Marley::ReggaeLink.new({:url => '/', :title => 'asdf'}))==[:link, {:url=>"/", :title=>"asdf"}, []]}
  T {@link.update(:url => '/asdf/')==[:link, {:url=>"/asdf/", :title=>"asdf"}, []]}

end
D 'parse' do
  D 'leave non-Reggae arrays as is' do
    T {Marley::Reggae.new([])==[]}
    T {Marley::Reggae.new(['asdf','ssss'])==["asdf", "ssss"]}
    T {Marley::Reggae.new(['asdf','ssss']).class==Marley::Reggae}
    T {Marley::Reggae.new(['asdf',{}]).to_resource==["asdf", {}]}
    T {Marley::Reggae.new(['asdf',{}]).to_resource.class==Marley::Reggae}
  end
 D 'a simple Reggae Resource' do
    T {Marley::Reggae.new(['resource',{}]).to_resource.class==Marley::ReggaeResource}
    T {Marley::Reggae.get_resource(['resource',{}]).class==Marley::ReggaeResource}
 end

  D 'parse a ReggaeSection' do
    T {(@section=Marley::Reggae.new([:section, {}]).to_resource)==[:section, {}]}
    T {@section.properties=={}}
  end
end






#conversion:  cf T {x$a==Jdf $a}j0f>
