
module Marley
  module Utils
    def self.class_attributes(attr_name)
      Module.new do |m|
        attr_accessor attr_name.to_sym
        inherit_attrs=lambda {|o, v|o.send("#{attr_name}=",v)}
        define_method :inherited do |c|
          val=send(attr_name.to_sym)
          inherit_attrs.call(c,val)
        end
      end
    end
    def self.per_request_attributes(attr_name, key_proc)
      Module.new do |m|
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
