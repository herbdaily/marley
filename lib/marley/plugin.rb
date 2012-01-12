
module Marley
  module Plugins
    class Plugin
      extend Marley::Utils.class_attr(:default_opts)
      def initialize(opts={})
        config(opts)
      end
      def apply(*klasses)
        plugin=self.class
        klasses.flatten.each do |klass|
          resource=klass.class==String ? MR.const_get(klass) : klass
          plugin.constants.include?('ClassMethods') && resource.extend(plugin.const_get('ClassMethods'))
          plugin.constants.include?('InstanceMethods') && resource.send(:include, plugin.const_get('InstanceMethods'))
          @opts[:class_attrs].to_a.each do |att|
            resource.extend Marley::Utils.class_attr(*att)
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
