

module Marley
  module Plugins
    class Section < Plugin
      @default_opts={:class_attributes =>  [[:section, nil]]}
      module ClassMethods
        def section
        end
      end
    end
  end
  module Joints
    class Section < Joint
      module Resources
        class Section
          def self.rest_get
            ReggaeSection.new(
              :title => 'Main Menu',
              :decription => 'Welcome',
              :navigation => MR.resources_responding_to(:section).map{|r| r.reggae_link('section')}
            )
          end
          def initialize(klass)
            ReggaeSection.new(klass.section)
          end
        end
      end
    end
  end
end
