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
        @sep=@opts[:path_separator]
      end
      module ClassMethods
        def roots
          list_dataset.filter(@path_col => 0)
        end
      end
      module InstanceMethods
        def tree_ds
          list_dataset.filter(@path_col.like("#{send(@path_col)}-#{id}_%")).order(@path_col)
        end
        def tree
          res=[self,[]]
          targets=[res[1]]
          current_depth=0
          tree_ds.all.each do |node|
            if node.depth>current_depth
              targets[node.depth]=[node,[]]
              targets[current_depth] << targets[node.depth]
              current_depth=node.depth
            elsif node.depth<current_depth
              current_depth=node.depth
              targets[current_depth]<<[node,[]]
            else
              targets[current_depth]<<[node,[]]
            end
          end
          res
        end
        def depth
          send(@path_col).split(@sep).length
        end
        def values_tree
        end
        def reggae_tree(node=nil)
          foo=(node? ? node : self).reggae_instance
          foo[2] = []
          foo
        end
        def new_child
          new({@path_col => "#{send(@path_col)}#{@sep}#{id}"})
        end
      end
    end
  end
end
