
module Marley
  module Utils
    class PerRequestAttribute
      attr_accessor :param,:key
      def initialize(param,key)
        @param,@key=[param,key]
      end
      def retrieve
        @param[$request[]]
      end
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
