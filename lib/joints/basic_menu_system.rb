
module Marley
  module Joints
    class BasicMenuSystem < Joint
      module Resources
        class Menu
          attr_accessor :title,:name,:description, :items
          def self.rest_get
            new.to_json
          end
          def self.requires_user?
            true
          end
          def to_json
            [:section,{:title => @title,:description => @description,:name => @name, :navigation => @items}]
          end
        end
      end
    end
  end
end
