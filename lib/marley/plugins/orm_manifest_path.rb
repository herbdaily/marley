module Marley
  module Plugins
    class OrmManifestPath < Plugin
      @default_opts={:path_col => :path, :path_separator => '-'}
      def apply(klass)
        super
      end
      def initialize(opts={})
        super
        @path_col=@opts[:path_col]
      end
      module ClassMethods
        def roots
          list_dataset.filter(@path_col => nil)
        end
      end
      module InstanceMethods
        def tree
        end
        def children
        end
        def new_child
        end
        def parents
        end
      end
    end
  end
end
