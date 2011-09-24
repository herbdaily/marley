
module Marley
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
        [:menu,{:title => @title,:description => @description,:items => @items}]
      end
    end
  end
end
