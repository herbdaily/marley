
module Sequel::Plugins::RestSection
  SECTION_PROPS='name','title','description','navigation'
  module ClassMethods
    SECTION_PROPS.each {|p| attr_accessor :"section_#{p}"}
    def section
      if SECTION_PROPS.find {|p| send(:"section_#{p}").to_s > ''}
        Marley::ReggaeSection.new [SECTION_PROPS.inject({}) {|props,p| props[p.to_sym]=send(:"section_#{p}");props }]
      end
    end
  end
end
module Marley
  module Joints
    class BasicMenuSystem < Joint
      def smoke
        super
        Sequel::Model.plugin :rest_section
      end
      module Resources
        class Menu
          class <<self
            attr_accessor :sections
          end
          attr_accessor :title,:name,:description, :navigation
          def self.rest_get
            new.to_json
          end
          def self.requires_user?
            ! $request[:path].to_a.empty?
          end
          def initialize
            @name='main'
            if $request[:user].new?
              u=$request[:user].to_a
              u[1].merge!({:description => 'If you don\'t already have an account, please create one here:'})
              @title="Welcome to #{$request[:opts][:app_name]}"
              @description='Login or signup here.'
              @navigation=[LOGIN_FORM,u]
            else
              @title = "#{$request[:opts][:app_name]} Main Menu"
              @description="Welcome to #{$request[:opts][:app_name]}, #{$request[:user].name}"
              @navigation=(self.class.sections || MR.constants).map do |rn|
                if (resource=MR.const_get(rn)).respond_to?(:section) && (s=resource.section)
                  [:link,{:title => s.title, :description =>s.description, :url => "#{resource.resource_name}/section" }]
                end
              end.compact
            end
          end
          def to_json
            [:section,{:title => @title,:description => @description,:name => @name, :navigation => @navigation}]
          end
        end
      end
    end
  end
end
