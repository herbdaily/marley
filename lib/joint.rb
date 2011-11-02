module Marley
  module Joints
    MR=Marley::Resources
    class Joint
      def initialize(*args)
        config(*args)
      end
      def add_resources
        self.class::Resources.constants.each do |c|
          Marley::Resources.const_set(c,self.class::Resources.const_get(c))
        end
      end
      def config(*args)
      end
      def menu_items
      end
    end
  end
end
