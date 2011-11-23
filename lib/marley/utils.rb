
module Marley
  module Utils
    def self.hash_keys_to_syms(hsh)
      hsh.inject({}) {|h,(k,v)| h[k.to_sym]= v.class==Hash ? hash_keys_to_syms(v) : v;h }
    end
  # @todo:  make options inheritable?
    def self.rest_opts_mod(name,opts,dynamic_key)
      Module.new do |m|
        opts.each {|opt| attr_accessor "#{name}_#{opt}"}
        define_method "rest_#{name}" do
          if opts.find {|opt| send(:"#{name}_#{opt}").to_s > ""}
            foo=opts.inject({}) do |h,k|
              i=send("#{name}_#{k}".sub(/^_/,''))
              h[k.to_sym]=i.class==Hash ? i[dynamic_key.call] : i
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
