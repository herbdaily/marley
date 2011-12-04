
require 'orm_rest_convenience_plugin.rb'
Marley.config(:http_auth => true)

# I try not to monkey patch, but for now this will do

class Marley::Resources::User < Sequel::Model
  def self.requires_user?
    ! ($request[:verb]=='rest_post' || ($request[:verb]=='rest_get' && $request[:path][1]=='new'))
  end
  def self.authenticate(credentials)
    find(:name => credentials[0], :password => credentials[1])
  end
end

