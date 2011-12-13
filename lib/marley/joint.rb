module Marley
  module Joints
    class Joint
      extend Marley::Utils.class_attributes(:default_opts)
      attr_accessor :opts
      def initialize(opts={})
        config(opts)
      end
      def smoke
        self.class::Resources.constants.each do |resource_name|
          MR.const_set(resource_name, self.class::Resources.const_get(resource_name)) unless (@opts[:resources] && ! @opts[:resources].include?(resource_name) )
          @opts[:plugins].to_a.each do |plugin_name|
            Marley.plugin(plugin_name).apply(resource_name)
          end
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
        @opts=(@opts || self.class.default_opts || {}).merge(opts)
      end
    end
  end
end
