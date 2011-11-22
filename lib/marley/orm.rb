module Marley
  module Orm
    module RestActions
      attr_accessor *REST_ACTIONS
      attr_accessor :klass
      def rest_actions
        ['get','post','put','delete'].inject({}) do |h,verb|
          i=send("#{verb}_actions")
          h[verb.to_sym]=i.class==Hash ? i[$request[:user].class] : i
          h
        end
      end
    end
  end
end
