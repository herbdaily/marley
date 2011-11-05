
module Marley
  module Joints
    class UserBasedNavigation < Joint
      LOGIN_FORM= [:instance,{:url => 'login',:description => 'Existing users please log in here:',:new_rec => true,:schema => [[:text,'name',RESTRICT_REQ],[:password,'password',RESTRICT_REQ]]}]
      module ClassMethods
        module User
          def sections
          end
        end
      end
      module Resources
        class MainMenu
          attr_accessor :title,:name,:description, :items
          def self.rest_get
            new.to_json
          end
          def initialize
            if $request[:user].new?
              u=$request[:user].to_a
              u[1].merge!({:description => 'If you don\'t already have an account, please create one here:'})
              @title="Welcome to #{$request[:opts][:app_name]}"
              @description='Login or signup here.'
              @items=[LOGIN_FORM,u]
            else
              $request[:user].class.sections
            end
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
