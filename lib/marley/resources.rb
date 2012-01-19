module Marley
  module Resources
    def self.resources_responding_to(method)
      constants.map{|c| r=const_get(c); r if r.respond_to?(method)}.compact
    end
    def self.map_resource_methods(method)
      constants.map{|c| r=const_get(c); r.send(method) if r.respond_to?(method)}.compact
    end
  end
end
