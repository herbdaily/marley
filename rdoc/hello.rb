require 'marley'
require 'marley/test_helpers'

Marley.config :http_auth => false
module Marley
  module Resources
    class Hello
      def self.rest_get
        'Hello World!'
      end
    end
  end
end
