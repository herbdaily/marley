module Marley
  module Joints
    # @abstract Subclass and implement one or more of the following modules within the class namespace:
    #    - Resources - All constansts in this module will be imported into Marley::Resources
    #    - ClassMethods - Modules within this module will extend any constant in Marley::Resources with the same name.
    #    - InstanceMethods - Modules within this module will append their features to any constant in Marley::Resources with the same name. 
    class Joint
      def initialize(opts={})
        config(opts)
      end
      def smoke
        klass=self.class
        { 'resources' => lambda {|c| MR.const_set(c,klass::Resources.const_get(c))},
          'class_methods' => lambda {|c| MR.const_get(c).extend klass::ClassMethods.const_get(c)},
          'instance_methods' => lambda {|c| klass::InstanceMethods.const_get(c).send :append_features, MR.const_get(c)}
        }.each_pair do |mod_name, importer|
          if klass.constants.include?(mod_name.camelize)
            klass.const_get(mod_name.camelize).constants.each do |c|
              importer.call(c) unless @opts[mod_name.to_sym] && ! @opts[mod_name.to_sym].include?(c.underscore)
            end
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
