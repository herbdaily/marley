require 'rubygems'
require 'marley'

module Marley
  module Joints
    class ExampleJoint < Joint
      module ClassMethods
        module Hello
          def self.rest_post
            new($request[:path][1])
          end
        end
      end
      module InstanceMethods
        module Hello
          def initialize(greeting)
            "#{greeting} world"
          end
        end
      end
      module Resources
        class GoodBye
          def self.rest_get
            "goodbye"
          end
        end
      end
    end
  end
end
