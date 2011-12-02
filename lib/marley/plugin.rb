
module Marley
  module Plugins
    # @abstract Subclass and implement one or more of the following modules within the class namespace:
    #    - Resources - All constansts in this module will be imported into Marley::Resources
    #    - ClassMethods - Modules within this module will extend any constant in Marley::Resources with the same name.
    #    - InstanceMethods - Modules within this module will append their features to any constant in Marley::Resources with the same name. 
    class Plugin
      def initialize(opts={})
        config(opts)
      end
      def apply(class_name)
        plugin=self.class
        resource=MR.const_get(class_name)
        plugin.constants.include?('ClassMethods') && resource.extend(plugin.const_get('ClassMethods'))
        plugin.constants.include?('InstanceMethods') && plugin.const_get('InstanceMethods').send(:append_features,resource) 
      end
      def config(opts)
        @opts=(@opts || {}).merge(opts)
      end
    end
  end
end
