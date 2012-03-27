module Marley
  module Plugins
    class MessageThreading < Plugin
      # implement 'Materialized Path for tree'
      module ClassMethods
        def topics(params=nil)
          filters=[]
          if params && params[:tags]
            filters << {:id => MR::Tag.join(:messages_tags, :tag_id => :id).select(:message_id).filter(:tag => params[:tags])}
          end
          filters.inject(self.list_dataset(:parent_id => nil)) {|ds,f| ds.filter(f)}
        end
        def list(params=nil)
          topics(params).eager_graph(:user).all.map{|t| t.thread}
        end
        def reggae_instance_list(params={})
          items=list_dataset(params).all
          if items.length==0
            Marley::ReggaeMessage.new(:title => 'Nothing Found')
          else
            cols=items[0].rest_cols 
            Marley::ReggaeInstanceList.new(
              :name => resource_name,
              :schema => items[0].reggae_schema(true) << [:resource,resource_name,RESTRICT_RO],
              :items => items.map{|i| cols.map{|c|i.send(c)}}
            )
          end
        end
      end
      module InstanceMethods
        def write_cols
          new? ? super.push(:topic_id, :parent_id) : super
        end
        def children
          self.class.list_dataset.filter(:parent_id => id)
        end
        def thread_vals
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
          list(lambda {date_created > Date.today - 2})
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
