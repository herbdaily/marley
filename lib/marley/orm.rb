module Marley
  module Orm
    module DynamicOpts
      def dynamic_opts(keys,prefix='')
        keys.inject({}) do |h,k|
          i=send("#{prefix}_#{k}".sub(/^_/,''))
          h[k.to_sym]=i.class==Hash ? i[@dynamic_key.call] : i
          h
        end
      end
    end
    # @todo:  make options inheritable?
    def self.rest_opts(name,opts,dynamic_key)
      Module.new do |m|
        include DynamicOpts
        @dynamic_key=dynamic_key
        opts.each {|opt| attr_accessor "#{name}_#{opt}"}
        define_method "rest_#{name}" do
          if opts.find {|opt| send(:"#{name}_#{opt}").to_s > ""}
            if Marley.constants.include?("Reggae#{name.camelcase}")
              Marley.const_get(:"Reggae#{name.camelcase}").new(dynamic_opts(opts,name))
            else
              dynamic_opts(opts,name) 
            end
          end
        end
      end
    end
    RestActions=rest_opts('actions',['get','post','put','delete'],lambda {$request[:user].class})
    RestSection=rest_opts('section',['name','title','description','navigation'],lambda {$request[:user].class})
  end
end
