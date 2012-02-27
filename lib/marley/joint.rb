module Marley
  module Joints
    Gem.find_files("marley/joints/*.rb").each do |f|
      self.autoload(File.basename(f,'.rb').camelize, f)
    end
    class Joint
      extend Marley::Utils::ClassAttrs
      class_attr(:default_opts,{})
      attr_accessor :opts
      def initialize(opts={})
        config(opts)
      end
      def smoke
        @opts[:required_joints].to_a.each do |j|
          Marley.joint(j)
        end
        resources=self.class::Resources
        resources.constants.each do |resource_name|
          @opts[:plugins].to_a.each do |plugin_name|
            Marley.plugin(plugin_name).apply(resources.const_get(resource_name))
          end
          MR.const_set(resource_name, resources.const_get(resource_name)) unless (@opts[:resources] && ! @opts[:resources].include?(resource_name) )
        end
        self
      end
      def config(opts)
        @opts=(@opts || self.class.default_opts || {}).merge(opts)
      end
    end
  end
end
