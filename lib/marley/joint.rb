module Marley
  module Joints
    # A suggested base class for joints.
    #
    # Joints which are subclasses should have at least one of the following modules:
    #
    # Resources - All constansts in this method will be imported into Marley::Resources
    #
    # ClassMethods - Modules within this module will exten any constant in Marley::Resources with the same name.
    #
    # InstanceMethods - Modules within this module will append their features to any constant in Marley::Resources with the same name. 
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
      end
      def config(opts)
        @opts=(@opts || {}).merge(opts)
      end
    end
  end
end
