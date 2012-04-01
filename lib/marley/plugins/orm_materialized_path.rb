module Marley
  module Plugins
    class OrmMaterializedPath < Plugin
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
        def roots(params={})
          list_dataset.filter({PATH_COL => nil}.update(params))
        end
        def path_col_num
          columns.index(PATH_COL)
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
        def new_child(vals={}); self.class.new({PATH_COL => children_path}.update(vals)); end
        def depth; path_arr.length; end
        def rest_cols;super - [PATH_COL];end

        def tree
          res=[block_given? ? (yield self) : [self,[]]]
          tree_ds.all.sort {|x,y| x.children_path_arr <=> y.children_path_arr}.each do |node|
            (1..(node.path_arr.length*2)).inject(res) {|arr,i| arr[-1]} << (block_given? ? (yield node) : [node,[]])
          end
          res[0]
        end
        def values_tree
          tree do |n|
            n.rest_cols.map{|c| n.send(c)} << []
          end
        end
      end
    end
  end
end
