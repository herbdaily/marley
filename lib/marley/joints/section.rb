module Marley
  module Plugins
    class Section < Plugin
      module ClassMethods
        def section
          ReggaeSection.new({
            :title => send_or_default(:section_title, resource_name.humanize) ,
            :navigation => send_or_nil(:section_nav),
            :description => send_or_nil(:section_desc)},
            send_or_nil(section_contents))
        end
        def section_link
          reggae_link('section').update(:title => resource_name.humanize.pluralize)
        end
        def section_nav
          model_actions.map{|a| reggae_link(a)}
        end
      end
    end
  end
  module Joints
    class Section < Joint
      class Section
        class << self
          attr_accessor :title,:navigation,:description
        end
        def self.section_link
          ReggaeLink.new({:url => '/' ,:title => 'Main Menu'})
        end
        def self.rest_get
          new.to_reggae
        end
        def initialze(title=nil,navigation=nil,description=nil)
          @title=title || self.class.title || self.class.name.sub(/.*::/,'').humanize ####
          @navigation=navigation || self.class.navigation
          @description=description || self.class.description
        end
        def to_reggae
          ReggaeSection.new(
            :title => @title
            :navigation => @navigation,
            :decription => @description
          )
        end
      end
      module Resources
        class MainMenu < Section
          def to_reggae
            ReggaeSection.new(
              :title => name.sub(/.*::/,'').humanize
              :decription => 'Welcome',
              :navigation => MR.resources_responding_to(:section).map{|r| r.section_link}.compact
            )
          end
        end
      end
    end
  end
end
