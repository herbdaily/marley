module Marley
  module Plugins
    class OrmManifestPath < Plugin
      @default_opts={:path_col => :path, :path_separator => '-'}
      def apply(klasses)
        super
      end
      def initialize(opts={})
        super
        [ClassMethods,InstanceMethods].each do |mod|
          mod.const_set(:PATH_COL,@opts[:path_col])
          mod.const_set(:SEP,@opts[:path_separator])
        end
      end
      module ClassMethods
        def roots
          list_dataset.filter(PATH_COL => 0)
        end
      end
      module InstanceMethods
        def tree_ds
          self.class.list_dataset.filter(PATH_COL.like("#{send(PATH_COL)}-#{id}_%")).order(PATH_COL)
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
          send(PATH_COL).split(SEP).length
        end
        def values_tree
        end
        def reggae_tree(node=nil)
          foo=(node? ? node : self).reggae_instance
          foo[2] = []
          foo
        end
        def new_child
          self.class.new({PATH_COL => "#{send(PATH_COL)}#{SEP}#{id}"})
        end
      end
    end
  end
end
