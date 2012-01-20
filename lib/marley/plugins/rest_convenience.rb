

module Marley
  module Plugins
    class RestConvenience < Plugin
      def apply(klass)
        super
      end
      module ClassMethods
        def resource_name; self.name.sub(/.*::/,'').underscore; end
        def url
        end
        def reggae_link(action=nil)
            ReggaeLink.new({:url => "/#{self.resource_name}/#{action}",:title => "#{action.to_s.humanize} #{self.resource_name.humanize}".strip})
        end
      end
      module InstanceMethods
        def resource_type
          if is_a? Sequel::Model
            :instance
          elsif is_a?  MP::Section::Section
            :section
          end
        end
      end
    end
  end
end
