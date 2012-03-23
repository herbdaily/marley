
module Marley
  module Plugins
    class MessageThreading < Plugin
      module ClassMethods
        def topics(params=nil)
          filters=[]
          if params && params[:tags]
            filters << {:id => MR::Tag.join(:messages_tags, :tag_id => :id).select(:message_id).filter(:tag => params[:tags])}
          end
          filters.inject(self.dataset.filter(:parent_id => nil)) {|ds,f| ds.filter(f)}
        end
        def list(params=nil)
          (params.is_a?(Sequel::Dataset) ?  params : topics(params)).eager(associations).all.map{|t| t.thread}
        end
      end
      module InstanceMethods
        def write_cols
          super.push(:topic_id, :parent_id)
        end
        def children
          self.class.filter(:parent_id => id).eager(associations)
        end
        def thread
          return reggae_instance if children.all.length==0
          foo=reggae_instance
          foo[2] = children.all.map{|m| m.thread} 
          foo
        end
        def before_save
          super
          self.topic_id||=self.class.max(:topic_id).to_i+1
        end
        def reply
          self.class.new(self.values.dup.delete_if{|k,v| k==:id}.merge({:parent_id => self[:id],:title => "re: #{title}"}))
        end
      end
    end
    class MessageNav < Plugin
      module ClassMethods
        def section_nav
          [
            self.reggae_link(:new, 'New Post'),
            self.reggae_link(:list, 'All Posts'),
            self.reggae_link(:recent_topics, 'Recent Topics'),
            Marley::ReggaeSection.new({:title => 'Topics Tagged With:', :navigation => MR::Tag.filter(:id => topics.join(:messages_tags).where(:messages__id => :message_id).select(:tag_id)).map{|t| reggae_link('list',t.tag,"#{resource_name}[tags]=#{t.tag}")}})
          ]
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
