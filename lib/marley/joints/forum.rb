
module Marley
  module Plugins
    class MessageThreading < Plugin
      module ClassMethods
        def topics(params=nil)
          self.dataset.filter(:parent_id => nil).filter(params || true)
        end
        def list(params=nil)
          (params.is_a?(Sequel::Dataset) ?  params : topics(params)).map{|t| t.thread}
        end
      end
      module InstanceMethods
        def write_cols
          super.push(:topic_id, :parent_id)
        end
        def children
          self.class.filter(:parent_id => id).all
        end
        def thread
          return reggae_instance if children.length==0
          foo=reggae_instance
          foo[2] = children.map{|m| m.thread} 
          foo
        end
        def before_save
          super
          self.topic_id||=self.class.max(:topic_id).to_i+1
        end
        def reply
          foo=reggae_instance.set_values(:parent_id => id,:title => "re: #{title}")
          foo.new_rec=true
          foo.url=self.class.new.url
          foo.schema.delete_if {|c| [:author,:id].include?(c[NAME_INDEX])}
          foo
        end
      end
    end
    class MessageNav < Plugin
      module ClassMethods
        def section_nav
          [
            self.reggae_link(:new, 'New Post'),
            self.reggae_link(:list, 'All Posts'),
            self.reggae_link(:recent, 'Recent Posts'),
            self.reggae_link(:recent_topics, 'Recent Topics'),
            Marley::ReggaeMsg.new(:title => 'Topics Tagged With:')
          ].concat(
            topics.map{|p|p.public_tags.map{|t| t.tag}}.flatten
          )
        end
        def section_contents
        end
        def recent
        end
        def recent_topics
          list(:date_created > Date.today - 2)
        end
      end
    end
  end
  module Joints
    class Forum < Joint
      Marley.plugin('orm_rest_convenience').apply(Sequel::Model)
      Marley.joint('user')
      Marley.joint('messages',{:tags => true})
      Marley.joint('section')
      Marley.plugin(:section).apply('PrivateMessage')
      Marley.plugin(:section).apply('PublicMessage')
      Marley.plugin(:message_threading).apply('PublicMessage')
      Marley.plugin(:message_nav).apply('PublicMessage')
      class << MR::PublicMessage
        def section_title;'Public Forums';end
      end
      module Resources
        class Topic < MJ::Messages::Message
        end
        class TopicTag < MR::Tag
        end
        class Admin < MR::User
          def self.requires_user?; true;end
        end
      end
    end
  end
end
