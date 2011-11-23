
module Marley
  module Joints
    class BasicMenuSystem < Joint
      def smoke
        super
        Sequel::Model.extend Orm::RestSection
      end
      module Resources
        class Menu
          include Orm::RestSection
          def self.rest_get
            new.rest_section
          end
          def self.requires_user?
            ! $request[:path].to_a.empty?
          end
          def initialize
            @name='main'
            if $request[:user].new?
              u=$request[:user].to_a
              u[1].merge!({:description => 'If you don\'t already have an account, please create one here:'})
              @section_title="Welcome to #{$request[:opts][:app_name]}"
              @section_description='Login or signup here.'
              @section_navigation=[LOGIN_FORM,u]
            else
              @section_title = "#{$request[:opts][:app_name]} Main Menu"
              @section_description="Welcome to #{$request[:opts][:app_name]}, #{$request[:user].name}"
              @section_navigation=(MR.constants - [self.class.to_s.sub(/.*::/,'').to_sym]).map do |rn|
                if (resource=MR.const_get(rn)).respond_to?(:rest_section) && (s=resource.rest_section) && s.title
                  [:link,{:title => s.title, :description =>s.description, :url => "#{resource.resource_name}/section" }]
                end
              end.compact
            end
          end
        end
      end
    end
  end
end
