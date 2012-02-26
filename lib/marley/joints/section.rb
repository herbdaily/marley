module Marley
  module Plugins
    class Section < Plugin
      module ClassMethods
        def section
          ReggaeSection.new({
            :name => send_or_default(:section_name, resource_name.underscore),
            :title => send_or_default(:section_title, resource_name.humanize),
            :navigation => send_or_nil(:section_nav),
            :description => send_or_nil(:section_desc)},
            send_or_nil(:section_contents))
        end
        def section_link
          reggae_link('section').update(:title => resource_name.humanize.pluralize)
        end
        def section_nav
          send_or_default(:model_actions,{})[:get].map{|a| reggae_link(a)}.compact
        end
        def authorize_rest_get(meth)
          super || (meth.to_s=='section' && (respond_to?(:current_user) ? ! current_user.new? : true) )
        end
      end
    end
  end
  module Joints
    class Section < Joint
      class Section
        Marley.plugin('rest_convenience').apply(self)
        Marley.plugin('section').apply(self)
        Marley.plugin('current_user_methods').apply(self) if MP.const_defined?(:CurrentUserMethods)
        def self.rest_get(params=nil)
          section
        end
      end
      module Resources
        class MainMenu < Section
          def self.requires_user?
            if respond_to?(:current_user)
              ! ($request[:path].nil? || $request[:path].empty?)
            else
              false
            end
          end
          def self.section_title
            Marley.config[:app_name]
          end
          def self.section_nav
            if respond_to?(:current_user) && (current_user.nil? || current_user.new?)
              [[:msg,{},'New users, please sign up below'],MR::User.new]
            else
              MR.resources_responding_to(:section).sort {|l,r|l.resource_name <=> r.resource_name}.map{|r| next if r==self; r.section}.compact
            end
          end
          def self.section_desc
            if respond_to?(:current_user) && (current_user.nil? || current_user.new?)
              ReggaeLink.new({:url => '/main_menu', :title => 'Existing users, please click here to log in.'})
            end
          end
          def self.section_link
            ReggaeLink.new({:url => '/',:title => 'Main Menu'})
          end
        end
      end
    end
  end
end
