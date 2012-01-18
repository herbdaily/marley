module Marley
  module Plugins
    class Section < Plugin
      @default_opts={ 
        :lazy_class_attrs =>  [ :current_user_class, :section_title,:section_nav,:section_desc,:section_contents]
      }
      def apply(*klasses)
        super
        klasses.each do |klass|
          p klass
          klass.instance_variable_set("@section_title",{:current_user_class => {:all => klass.name.to_s.humanize}})
        end
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
