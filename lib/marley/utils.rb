
module Marley
  module Utils
    def self.many_to_many_join(lclass, rclass)
      join_table=[lclass.table_name.to_s,rclass.table_name.to_s ].sort.join('_')
      lclass.many_to_many(rclass.resource_name.pluralize.to_sym,:join_table => join_table,:class =>rclass, :left_key => lclass.foreign_key_name, :right_key => rclass.foreign_key_name)
      rclass.many_to_many(lclass.resource_name.pluralize.to_sym,:join_table => join_table, :class =>lclass,:left_key => rclass.foreign_key_name, :right_key => lclass.foreign_key_name)
    end
    def self.combine(old,new)
      if old.is_a?(Hash) && new.is_a?(Hash)
        old.merge(new) {|k,o,n|Marley::Utils.combine(o,n)}
      elsif old.is_a?(Array) && new.is_a?(Array)
        (old + new).uniq
      else
        new
      end
    end
    def self.class_attr(attr_name, val=nil, op=nil, &block)
      if !block
        if !op
          block= lambda {|old, new| Marley::Utils.combine(old,new)}
        else
          block = lambda{ |o, x| o.__send__(op, x) }
        end
      end
      Module.new do |m|
        define_method :"#{attr_name}!" do |*args|
          if instance_variable_defined?("@#{attr_name}")
            instance_variable_get("@#{attr_name}")
          else
            instance_variable_set("@#{attr_name}", Marshal.load(Marshal.dump(val)))
          end
        end
        define_method attr_name.to_sym do
          ancestors.reverse.inject(Marshal.load(Marshal.dump(val))) do |v, a|
            if a.respond_to?(:"#{attr_name}!")
              block.call(v,a.__send__(:"#{attr_name}!"))
            else
              v
            end
          end
        end
      end
    end
    def self.class_attributes(attr_name, val=nil, &block)
      Module.new do |m|
        attr_writer attr_name.to_sym
        @attr_name, @val=[attr_name,val]
        def self.extended(o)
          super
          o.send("#{@attr_name}=",Marshal.load(Marshal.dump(@val)))
        end
        define_method :"#{attr_name}!" do |*args|

        end
        define_method attr_name.to_sym do
          my_val=instance_variable_defined?("@#{attr_name}") && instance_variable_get("@#{attr_name}")
          super_val=superclass.respond_to?(attr_name.to_sym) && Marshal.load(Marshal.dump(superclass.send(attr_name.to_sym)))
          return my_val unless super_val
          if instance_variable_defined?("@#{attr_name}")
            Marley::Utils.combine(super_val, my_val)
          else
            send("#{attr_name}=",super_val)
          end
        end
      end
    end
    def self.hash_keys_to_syms(hsh)
      hsh.inject({}) {|h,(k,v)| h[k.to_sym]= v.class==Hash ? hash_keys_to_syms(v) : v;h }
    end
  end
end
