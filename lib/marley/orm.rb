module Marley
  module Orm
    module DynamicOpts
      attr_accessor :reggae_dynamic_key
      def dynamic_opts(keys,prefix='')
        keys.inject({}) do |h,k|
          i=send("#{prefix}_#{k}".sub(/^_/,''))
          h[k.to_sym]=i.class==Hash ? i[@dynamic_key.call] : i
          h
        end
      end
    end
    def self.rest_opts(name,opts,dynamic_key)
      Module.new do |m|
        include DynamicOpts
        @dynamic_key=dynamic_key
        opts.each {|opt| attr_accessor "#{name}_#{opt}"}
        define_method "rest_#{name}" do
          dynamic_opts(opts,name)
        end
      end
    end
    RestActions=rest_opts('actions',['get','post','put','delete'],lambda {$request[:user].class})
#    module RestActions
#      include DynamicOpts
#      @dynamic_key=lambda {$request[:user].class}
#      REST_ACTIONS=['get','post','put','delete']
#      REST_ACTIONS.each {|p| attr_accessor :"#{p}_actions"}
#      def rest_actions
#        dynamic_opts(REST_ACTIONS,'','actions')
#      end
#    end
    module RestSection
      include DynamicOpts
      @dynamic_key=lambda {$request[:user].class}
      SECTION_PROPS=['name','title','description','navigation']
      SECTION_PROPS.each {|p| attr_accessor :"section_#{p}"}
      def rest_section
        if SECTION_PROPS.find {|p| send(:"section_#{p}").to_s > ''}
          Marley::ReggaeSection.new(dynamic_opts(SECTION_PROPS,'section'))
        end
      end
    end
  end
end
