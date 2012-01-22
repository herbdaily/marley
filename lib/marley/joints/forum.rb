
module Marley
  module Plugins
  end
  module Joints
    class Forum < Joint
      def smoke
        Marley.plugin('orm_rest_convenience').apply(Sequel::Model)
        Marley.joint('user')
        Marley.joint('messages',{:tags => true})
        Marley.joint('section')

        #Marley.plugin('current_user_methods').apply(Sequel::Model)
      end
    end
  end
end
