
module Marley
  class Reggae < Array
    class << self
      attr_accessor :valid_properties
      def mk_prop_methods
        @valid_properties && @valid_properties.each do |meth|
          define_method(meth) {properties[meth].respond_to?(:to_resource) ? properties[meth].to_resource : properties[meth]} 
          define_method(:"#{meth}=") {|val|properties[meth]=val} 
        end
      end
      def get_resource(*args)
        self.new(*args).to_resource
      end
    end
    def initialize(*args)
      super
      self[1]=Utils.hash_keys_to_syms(self[1]) if self[1].class==Hash
      self.class.mk_prop_methods
    end
    def properties
      self[1] || nil
    end
    def resource_type
      [String, Symbol].include?(self[0].class) ? self[0].to_sym : nil
    end
    def is_resource?
      ! resource_type.nil?
    end
    def contents
      is_resource? ? Reggae.new(self[2 .. -1]) : nil
    end
    def contents=(*args)
      self[2]=*args
      while length>3;delete_at -1;end
    end
    def [](*args)
      super.class==Array ?  Reggae.new(super).to_resource : super
    end
    def to_resource
      is_resource? ? Marley.const_get("Reggae#{resource_type.to_s.camelize}".to_sym).new(self) : self
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
    def resource_type
      self.class.to_s.sub(/.*Reggae/,'').underscore.to_sym
    end
    def initialize(*args)
      if args[0].class==Hash
        initialize [resource_type,args[0]]
      else
        super
      end
    end
  end
  class ReggaeSection < ReggaeResource
    self.valid_properties=[:title,:description]
    def navigation
      properties[:navigation].map{|n|Reggae.get_resource(n)}
    end
  end
  class ReggaeLink < ReggaeResource
    self.valid_properties=[:title,:description,:url]
  end
  class ReggaeInstance < ReggaeResource
    self.valid_properties=[:name,:new_rec,:schema,:search,:url,:get_actions,:delete_action]
    def initialize(*args)
      super
      self.schema=ReggaeSchema.new(self.schema)
    end
    def to_params
      schema.inject({}) do |params,spec| 
        params["#{name}[#{spec.col_name}]"]=spec.col_value unless (spec.col_restrictions & RESTRICT_RO > 0)
        params
      end
    end
    def instance_action_url(action_name)
      "#{url}#{action_name}" if get_actions.include?(action_name.to_s)
    end
    def col_value(col_name,col_value=nil)
      col=schema[col_name]
      col.col_value=col_value if col_value
      col.col_value
    end
    def set_values(col_hash)
      col_hash.each_pair {|k,v| col_value(k,v)}
      self
    end
  end
  class ReggaeInstanceList < ReggaeResource
    self.valid_properties=[:name,:description,:get_actions,:delete_action,:items]
    #not implemented yet
  end
  class ReggaeMsg < ReggaeResource
    self.valid_properties=[:title,:description]
  end
  class ReggaeError < ReggaeResource
    self.valid_properties=[:error_type,:description,:error_details]
  end
  class ReggaeSchema < Array
    def initialize(*args)
      super
      replace(map{|spec| ReggaeColSpec.new(spec)})
    end
    def [](i)
      if i.class==Fixnum
        super
      else
        find {|cs|cs.col_name.to_s==i.to_s}
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
