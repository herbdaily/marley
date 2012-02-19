
module Marley
  module Plugins
    class MessageThreading < Plugin
      def apply(*klasses)
        super
        klasses.each {|klass| klass.plugin :tree}
      end
      module ClassMethods
        def topics
          self.dataset.filter(:parent_id => nil)
        end
        def list(params=nil)
          topics.map{|t| t.thread}
        end
      end
      module InstanceMethods
        def topic_msg
          self.class.topics.filter(:topic_id => topic_id).first
        end
        def topic
          self.topic_msg.tree
        end
        def children
          self.class.filter(:parent_id => id).all
        end
        def thread
          children.length > 0 ? reggae_instance << children.map{|m| m.thread} : reggae_instance
        end
        def reply
          foo=reggae_instance.set_values(:parent_id => id,:title => "re: #{title}")
          foo.new_rec=true
          foo.schema.delete_if {|c| [:author,:id].include?(c[NAME_INDEX])}
          foo
        end
      end
    end
  end
  module Joints
    class Forum < Joint
      def smoke
        Marley.plugin('orm_rest_convenience').apply(Sequel::Model)
        Marley.joint('user')
        Marley.joint('messages',{:tags => true})
        Marley.joint('section')
        Marley.plugin(:section).apply('PrivateMessage')
        Marley.plugin(:section).apply('PublicMessage')
        Marley.plugin(:message_threading).apply('PublicMessage')
      end
    end
  end
end
