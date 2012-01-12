

module Marley
  module Plugins
    class Section < Plugin
      @default_opts={ 
        :class_attributes =>  [:section_title,:section_nav,:section_desc,:section_contents],
        :lazy_key => lambda {MR::User.current_user.class}
      }
      def apply(*klasses)
        super
      end
      module ClassMethods
        def section
          ReggaeSection.new({
            :title => section_title,
            :navigation => section_nav,
            :description => section_desc},
            section_contents)
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
        end
      end
    end
  end
end
