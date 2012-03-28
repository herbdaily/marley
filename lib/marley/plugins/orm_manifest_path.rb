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
          res=block_given? ? (yield self) : [self,[]]
          targets=[res[-1].is_a?(Array) ? res[-1] : res]
          current_depth=0
          tree_ds.all.each do |node|
            n=block_given? ? (yield node) : [node,[]]
            if node.depth>current_depth
              targets[node.depth]=n
              targets[current_depth] << targets[node.depth]
              current_depth=node.depth
            elsif node.depth<current_depth
              current_depth=node.depth
              targets[current_depth]<<n
            else
              targets[current_depth]<<n
            end
          end
          res
        end
        def depth
          send(PATH_COL).split(SEP).length
        end
        def values_tree
          tree do |n|
            n.rest_cols.map{|c| n.send(c)}
          end
        end
        def reggae_tree(node=nil)
        end
        def new_child
          self.class.new({PATH_COL => "#{send(PATH_COL)}#{SEP}#{id}"})
        end
      end
    end
  end
end
