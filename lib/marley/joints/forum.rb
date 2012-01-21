
module Marley
  module Plugins
  end
  module Joints
    class Forum < Joint
      def smoke
        Marley.plugin('orm_rest_convenience').apply(Sequel::Model)
        Marley.joint('user')

        #Marley.plugin('current_user_methods').apply(Sequel::Model)
        #Marley.joint('messages')
        #Marley.joint('tags')
        #Marley.joint('section')
      end
    end
  end
end
