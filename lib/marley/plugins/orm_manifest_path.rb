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
        def tree_ds; self.class.list_dataset.filter(PATH_COL.like("#{children_path}%")); end
        def _path;send(PATH_COL);end
        def path_arr; _path.to_s.split(SEP).map &:to_i; end
        def root_id; path_arr[0]; end
        def parent_id; path_arr[-1]; end
        def children_path;("#{_path}#{id}#{SEP}");end
        def children_path_arr; children_path.split(SEP).map &:to_i; end
        def new_child; self.class.new({PATH_COL => children_path}); end
        def depth; path_arr.length; end

        def tree
          res=block_given? ? (yield self) : [self,[]]
          tree_ds.all.sort {|x,y| x.children_path_arr <=> y.children_path_arr}.each do |node|
            target=node.path_arr.inject(res) {|arr,i| arr[-1]}
            target << [node,[]]
          end
          res
        end
        def tree_foo
          res=block_given? ? (yield self) : [self,[]]
          targets=[]
          current_depth=depth
          targets[current_depth]=res[-1].is_a?(Array) ? res[-1] : res
          tree_ds.all.sort {|x,y| x.children_path_arr <=> y.children_path_arr}.each do |node|
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
        def values_tree
          tree do |n|
            n.rest_cols.map{|c| n.send(c)}
          end
        end
        def reggae_tree(node=nil)
        end
      end
    end
  end
end
