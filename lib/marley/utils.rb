
module Marley
  module Utils
    def self.many_to_many_join(lclass, rclass)
      join_table=[lclass.table_name.to_s,rclass.table_name.to_s ].sort.join('_')
      lclass.many_to_many(rclass.resource_name.pluralize.to_sym,:join_table => join_table,:class =>rclass, :left_key => lclass.foreign_key_name, :right_key => rclass.foreign_key_name)
      rclass.many_to_many(lclass.resource_name.pluralize.to_sym,:join_table => join_table, :class =>lclass,:left_key => rclass.foreign_key_name, :right_key => lclass.foreign_key_name)
    end
    def self.class_attributes(attr_name, val=nil)
      Module.new do |m|
        attr_accessor attr_name.to_sym
        @attr_name, @val=[attr_name,val]
        def self.extended(o)
          o.send("#{@attr_name}=",@val)
        end
        define_method :inherited do |c|
          super
          c.send("#{attr_name}=",send(attr_name.to_sym))
        end
      end
    end
    def self.hash_keys_to_syms(hsh)
      hsh.inject({}) {|h,(k,v)| h[k.to_sym]= v.class==Hash ? hash_keys_to_syms(v) : v;h }
    end
    # @todo:  make options inheritable?
    def self.rest_opts_mod(name,opts,key_proc)
      Module.new do |m|
        @create_opts=[name,opts,key_proc]
        def self.create_opts
          @create_opts
        end
        def self.new(name=nil,opts=nil,key_proc=nil)
          Marley::Utils.rest_opts_mod(*@create_opts)
        end
        opts.each {|opt| attr_accessor "#{name}_#{opt}"}
        define_method "rest_#{name}" do
          if opts.find {|opt| send(:"#{name}_#{opt}").to_s > ""}
            foo=opts.inject({}) do |h,k|
              i=send("#{name}_#{k}".sub(/^_/,''))
              h[k.to_sym]=i.class==Hash ? i[key_proc.call] : i
              h
            end
            if Marley.constants.include?("Reggae#{name.camelcase}")
              Marley.const_get(:"Reggae#{name.camelcase}").new(foo)
            else
              foo 
            end
          end
        end
      end
    end
  end
  RestActions=Utils.rest_opts_mod('actions',['get','post','put','delete'],lambda {$request[:user].class})
end
