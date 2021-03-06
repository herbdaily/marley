
module Marley
  module Utils
    module ClassAttrs
      def lazy_class_attrs(key_proc,atts,op=nil,&block)
        atts.to_a.each do |att|
          att=[att] unless att.is_a?(Array)
          class_attr(att[0], {key_proc => att[1]}, op, &block)
          include(Module.new do |m|
            define_method :"_#{att[0]}" do
              a=self.class.send(att[0])
              a.keys.inject(nil) {|res,key| 
                if self.respond_to?(key)
                  all=a[key][:all]
                  v=(a[key].has_key?(dyn_key=self.send(key)) && a[key][dyn_key] ) || all || res
                  Marley::Utils.combine(res,Marley::Utils.combine(all, v)) 
                else
                  Marley::Utils.combine(res,a[key])
                end
              }
            end
          end)
        end
      end
      def class_attr(attr_name, val=nil, op=nil, &block)
        block||=op ? lambda{ |o, x| o.__send__(op, x) } : lambda {|old, new| Marley::Utils.combine(old,new)}
        extend(Module.new do |m|
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
        end)
      end
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
    def self.sti(klass)
      klass.plugin :single_table_inheritance, :"#{klass.to_s.sub(/.*::/,'').underscore}_type", :model_map => lambda{|v| MR.const_get(v.to_sym)}, :key_map => lambda{|clss|clss.name.sub(/.*::/,'')}
    end
    def self.many_to_many_join(lclass, rclass,lopts={},ropts={})
      join_table=[lclass.table_name.to_s,rclass.table_name.to_s ].sort.join('_').to_sym
      lclass.many_to_many(rclass.resource_name.pluralize.to_sym,{:join_table => join_table,:class =>rclass, :left_key => lclass.foreign_key_name, :right_key => rclass.foreign_key_name}).update(lopts)
      rclass.many_to_many(lclass.resource_name.pluralize.to_sym,{:join_table => join_table, :class =>lclass,:left_key => rclass.foreign_key_name, :right_key => lclass.foreign_key_name}.update(ropts))
    end
    def self.hash_keys_to_syms(hsh)
      hsh.inject({}) {|h,(k,v)| h[k.to_sym]= v.class==Hash ? hash_keys_to_syms(v) : v;h }
    end
  end
end
