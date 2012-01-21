module Marley
  module Plugins
    class Section < Plugin
      module ClassMethods
        def section
          ReggaeSection.new({
            :title => send_or_default(:section_title, resource_name.humanize) ,
            :navigation => send_or_nil(:section_nav),
            :description => send_or_nil(:section_desc)},
            send_or_nil(:section_contents))
        end
        def section_link
          reggae_link('section').update(:title => resource_name.humanize.pluralize)
        end
        def section_nav
          send_or_default(model_actions,[]).map{|a| reggae_link(a)}
        end
      end
    end
  end
  module Joints
    class Section < Joint
      class Section
        Marley.plugin('rest_convenience').apply(self)
        Marley.plugin('section').apply(self)
        def self.rest_get
          section
        end
      end
      module Resources
        class MainMenu < Section
          def self.section_nav
            MR.resources_responding_to(:section).map{|r| r.section_link}.compact
          end
          def self.section_link
            ReggaeLink.new({:url => '/',:title => 'Main Menu'})
          end
        end
      end
    end
  end
end
