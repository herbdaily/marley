require 'marley'
require 'marley/test_helpers'

Marley.config :http_auth => false
module Marley
  module Resources
    class Hello
      def self.rest_get
        @who=$request[:get_params][:who] || 'World'
        "Hello #{@who}!"
      end
    end
  end
end
