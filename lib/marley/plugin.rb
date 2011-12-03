
module Marley
  module Plugins
    class Plugin
      def initialize(opts={})
        config(opts)
      end
      def apply(klass)
        plugin=self.class
        resource=klass.class==String ? MR.const_get(klass) : klass
        plugin.constants.include?('ClassMethods') && resource.extend(plugin.const_get('ClassMethods'))
        plugin.constants.include?('InstanceMethods') && plugin.const_get('InstanceMethods').send(:append_features,resource) 
        nil
      end
      def config(opts)
        @opts=(@opts || {}).merge(opts)
      end
    end
  end
end
