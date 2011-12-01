module Marley
  module Joints
    # @abstract Subclass and implement one or more of the following modules within the class namespace:
    #    - Resources - All constansts in this module will be imported into Marley::Resources
    #    - ClassMethods - Modules within this module will extend any constant in Marley::Resources with the same name.
    #    - InstanceMethods - Modules within this module will append their features to any constant in Marley::Resources with the same name. 
    class Joint
      MODS=['Resources','Plugins']
      MODS.each {|mod| const_set(mod,Module.new)}
      def self.mods
        MODS.map {|mod_name| self.const_get(mod_name) } 
      end
      def initialize(opts={})
        config(opts)
      end
      def smoke
        self.class::Resources.constants.each do |resource_name|
          MR.const_set(resource_name, self.class::Resources.const_get(resource_name)) unless (@opts[:resources] && ! @opts[:resources].include?(resource_name))
        end
        self.class.constants.grep(/.+Plugin$/).each do |plugin_name|
          plugin=self.class.const_get(plugin_name)
          resource_name=plugin_name.sub(/Plugin$/,'')
          if MR.constants.include?(resource_name)
            resource=MR.const_get(resource_name)
            plugin.constants.include?('ClassMethods') && resource.extend(plugin.const_get('ClassMethods'))
            plugin.constants.include?('InstanceMethods') && plugin.const_get('InstanceMethods').send(:append_features,resource)
          end
        end
        self
      end
      def config(opts)
        @opts=(@opts || {}).merge(opts)
      end
    end
  end
end
