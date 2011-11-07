
module Marley
  class Reggae < Array
    class << self
      attr_accessor :valid_properties
      def mk_prop_methods
        @valid_properties && @valid_properties.each do |meth|
          define_method(meth) {properties[meth]} 
          define_method(:"#{meth}=") {|val|properties[meth]=val} 
        end
      end
    end
    def initialize(*args)
      super
      self.class.mk_prop_methods
      self
    end
    def resource_type
      [String, Symbol].include?(self[0].class) ? self[0].to_s : nil
    end
    def is_resource?
      ! resource_type.nil?
    end
    def properties
      self[1].class==Hash ? Utils.hash_keys_to_syms(self[1]) : nil
    end
    def contents
      is_resource? ? Reggae.new(self[2 .. -1]) : nil
    end
    def [](*args)
      super.class==Array ?  Reggae.new(super).to_resource : super
    end
    def to_resource
      is_resource? ? Marley.const_get("Reggae#{resource_type.camelize}".to_sym).new(self) : self
    end
    def find_instances(rn,instances=Reggae.new([]))
      if self.class==ReggaeInstance && self.name.to_s==rn 
        instances << self
      else
        (is_resource? ? contents : self).each {|a| a && Reggae.new(a).to_resource.find_instances(rn,instances)}
      end
      instances
    end
  end
  class ReggaeResource < Reggae
  end
  class ReggaeSection < ReggaeResource
    self.valid_properties=[:title,:description,:navigation]
  end
  class ReggaeLink < ReggaeResource
    self.valid_properties=[:title,:description,:url]
  end
  class ReggaeInstance < ReggaeResource
    self.valid_properties=[:name,:new_rec,:search,:url,:get_actions,:delete_action]
    def schema
      ReggaeSchema.new(self.properties[:schema])
    end
    def to_params
      resource_name=name
      schema.inject({}) do |params,spec| 
        s=ReggaeColSpec.new(spec)
        params["#{resource_name}[#{s.col_name}]"]=s.col_value unless (s.col_restrictions & RESTRICT_RO > 0)
        params
      end
    end
    def instance_action_url(action_name)
      "#{url}#{action_name}" if get_actions.include?(action_name.to_s)
    end
  end
  class ReggaeInstanceList < ReggaeResource
    self.valid_properties=[:name,:description,:get_actions,:delete_action,:items]
    def schema
      ReggaeSchema.new(self.properties[:schema])
    end
  end
  class ReggaeMsg < ReggaeResource
    self.valid_properties=[:title,:description]
  end
  class ReggaeError < ReggaeResource
    self.valid_properties=[:error_type,:description,:error_details]
  end
  class ReggaeSchema < Array
    def [](i)
      if i.class==Fixnum
        ReggaeColSpec.new(super).to_resource 
      else
        ReggaeColSpec.new(find {|cs|ReggaeColSpec.new(cs).col_name==i.to_s})
      end
    end
  end
  class ReggaeColSpec < Array
    ['col_type','col_name','col_restrictions', 'col_value'].each_with_index do |prop_name, i|
      define_method(prop_name.to_sym) {self[i]} 
      define_method(:"#{prop_name}=") {|val|self[i]=val} 
    end
  end
end
