module Marley
  module Joints
    MR=Marley::Resources
    class Joint
      def initialize(opts={})
        config(opts)
      end
      def add_resources
        self.class::Resources.constants.each do |c|
          Marley::Resources.const_set(c,self.class::Resources.const_get(c)) unless @opts[:import] && ! @opts[:import].include?(c.underscore)
        end
      end
      def config(opts)
        @opts=(@opts || {}).merge(opts)
      end
      def menu_items
      end
    end
  end
end
