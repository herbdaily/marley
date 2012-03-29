module Marley
  module Plugins
    class MessageThreading < Plugin
      def apply(*klasses)
        super
        klasses.flatten.each do |klass|
          Marley.plugin('orm_materialized_path').apply(klass)
        end
      end
      module ClassMethods
        def topics(params=nil)
          filters=[]
          if params && params[:tags]
            filters << {:id => MR::Tag.join(:messages_tags, :tag_id => :id).select(:message_id).filter(:tag => params[:tags])}
          end
          filters.inject(self.roots) {|ds,f| ds.filter(f)}
        end
        def list(params=nil)
          topics(params).eager_graph(:user).all.map{|t| t.thread}
        end
        def reggae_instance_list(params={})
          t=topics(params).all
          if t.length==0
            Marley::ReggaeMsg.new(:title => 'Nothing Found')
          else
            Marley::ReggaeInstanceList.new(
              :name => resource_name,
              :schema => t[0].reggae_schema(true) << [:resource,resource_name,RESTRICT_RO],
              :items => t.map{|t| t.thread_vals}
            )
          end
        end
      end
      module InstanceMethods
        def thread_vals;values_tree;end
        def thread; tree;end
        def write_cols
          new? ? super.push(:topic_id, :path) : super
        end
        def before_save
          super
          self.topic_id||=self.class.max(:topic_id).to_i+1
        end
        def reply
          new_child(:title => "re: #{title}")
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
