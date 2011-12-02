
module Marley
  module Plugins
    module RestActions
     InstanceActions=Marley::Utils.rest_opts_mod('actions',['get','post','put','delete'],lambda {$request[:user].class})
    end
  end
end
