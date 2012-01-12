
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
      block||=op ? lambda{ |o, x| o.__send__(op, x) } : lambda {|old, new| Marley::Utils.combine(old,new)}
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
    def self.hash_keys_to_syms(hsh)
      hsh.inject({}) {|h,(k,v)| h[k.to_sym]= v.class==Hash ? hash_keys_to_syms(v) : v;h }
    end
  end
end
