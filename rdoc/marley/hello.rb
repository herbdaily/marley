require 'marley'
require 'marley/test_helpers'

module Marley
  module Resources
    class Hello
      def self.requires_user?;false;end
      def self.rest_get
        'Hello World!'
      end
    end
  end
end
