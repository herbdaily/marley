require 'rubygems'
module Marley
  module Plugins
    Gem.find_files("marley/plugins/*.rb").each do |f|
      self.autoload(File.basename(f,'.rb').camelize, f)
    end
    class Plugin
      extend Marley::Utils::ClassAttrs
      class_attr(:default_opts,{})
      def initialize(opts={})
        config(opts)
      end
      def apply(*klasses)
        plugin=self.class
        klasses.flatten.each do |klass|
          resource=klass.class==String ? MR.const_get(klass) : klass
          @opts[:required_plugins].to_a.each do |p|
            Marley.plugin(p).apply(klass)
          end
          plugin.constants.include?('ClassMethods') && resource.extend(plugin.const_get('ClassMethods'))
          plugin.constants.include?('InstanceMethods') && resource.send(:include, plugin.const_get('InstanceMethods'))
          if @opts[:lazy_class_attrs] || @opts[:class_attrs] 
            resource.extend Marley::Utils::ClassAttrs
          end
          if lazy_attrs=@opts[:lazy_class_attrs]
            resource.lazy_class_attrs(lazy_attrs[0],lazy_attrs[1..-1])
          end
          @opts[:class_attrs].to_a.each do |att|
            resource.class_attr(*att)
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
