
module Marley
  module Plugins
    class Plugin
      extend Marley::Utils.class_attributes(:default_opts)
      def initialize(opts={})
        config(opts)
      end
      def apply(*klasses)
        plugin=self.class
        klasses.flatten.each do |klass|
          resource=klass.class==String ? MR.const_get(klass) : klass
          resource.respond_to?(:instance_extensions) || Marley::Utils.extend_new_instances(resource)
          plugin.constants.include?('ClassMethods') && resource.extend(plugin.const_get('ClassMethods'))
          #plugin.constants.include?('InstanceMethods') && plugin.const_get('InstanceMethods').send(:append_features,resource) 
          plugin.constants.include?('InstanceMethods') && resource.instance_extensions << plugin.const_get('InstanceMethods')
          @opts[:additional_extensions].to_a.each do |ext|
            resource.extend(ext)
          end
        end
        nil
      end
      def config(opts)
        @opts=(@opts || self.class.default_opts || {}).merge(opts)
      end
    end
  end
end
