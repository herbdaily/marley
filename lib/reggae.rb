
module Marley
  class Reggae < Array
    @@valid_properties=[]
    def resource_type
      self[0].class==String ? self[0] : nil
    end
    def is_resource?
      ! resource_type.nil?
    end
    def properties
      self[1].class==Hash ? self[1] : nil
    end
    def contents
      is_resource? ? Reggae.new(self[2 .. -1]) : nil
    end
    def [](*args)
      Reggae.new(super).to_resource rescue super
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
    def method_missing(meth, *args, &block)
      if @@valid_properties.include?(meth.to_s)
        properties[meth.to_s]
      else
        super
      end
    end
  end
  class ReggaeResource < Reggae
  end
  class ReggaeMsg < ReggaeResource
    @@valid_properties=['title','description']
  end
  class ReggaeMenu < ReggaeResource
    @@valid_properties=['title','description','items']
  end
  class ReggaeUri < ReggaeResource
    @@valid_properties=['title','description','url']
  end
  class ReggaeInstance < ReggaeResource
    @@valid_properties=['name','new_rec','search','url','instance_get_actions']
    def schema
      ReggaeSchema.new(self.properties["schema"])
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
      "#{url}#{action_name}" if instance_get_actions.include?(action_name.to_s)
    end
  end
  class ReggaeValidation < ReggaeResource
  end
  class ReggaeSchema < Array
    def [](*args)
      ReggaeColSpec.new(super).to_resource 
    end
    def method_missing(meth, *args, &block)
      if spec=ReggaeColSpec.new(find {|cs|ReggaeColSpec.new(cs).col_name==meth.to_s})
        spec.col_value
      else
        super
      end
    end
  end
  class ReggaeColSpec < Array
    ['col_type','col_name','col_restrictions', 'col_value'].each_with_index do |prop_name, i|
      define_method(prop_name.to_sym) {self[i]} 
    end
  end
end
