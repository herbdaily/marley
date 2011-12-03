
module Marley
  module Plugins
    class ExamplePlugin < Plugin
      module ClassMethods
        def rest_post
          new($request[:path][1])
        end
      end
      module InstanceMethods
        def initialize(greeting)
          @greeting=greeting
        end
        def to_json
          "#{@greeting} world"
        end
      end
    end
  end
end
