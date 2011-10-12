
module Marley
  module Resources
    class Tag < Sequel::Model
      module TaggingClassMethods
        def list(params={})
          if associations.include?(:public_tags)
            specified_tags=params.delete(:tags)
            specified_user_tags=params.delete(:user_tags)
          else
            specified_user_tags=params.delete(:tags)
          end
          tag_ids=PublicTag.filter(:tag => specified_tags.split(/\s*,\s*/)).select(:id) if specified_tags
          user_tag_ids=$request[:user].user_tags_dataset.filter(:tag => specified_user_tags.split(/\s*,\s*/)).select(:id) if specified_user_tags
          items=filter(params)
          #would love to make the following line more generic...
          items=filter("author_id=#{$request[:user][:id]} or recipients like('%#{$request[:user][:name]}%')".lit) if new.rest_cols.include?(:recipients)
          items=items.join(:messages_tags,:message_id => :id).filter(:tag_id => tag_ids) if specified_tags
          items=items.join(:messages_tags,:message_id => :id).filter(:tag_id => user_tag_ids) if specified_user_tags
          items.group(:thread_id).order(:max.sql_function(:date_created).desc,:max.sql_function(:date_updated).desc).map{|t|self[:parent_id => nil, :thread_id => t[:thread_id]].thread} rescue []
        end
      end
      module TaggingMethods
        def rest_associations
          if ! new?
            [ respond_to?(:public_tags) ? :public_tags : nil, respond_to?(:user_tags) ? user_tags_dataset.current_user_tags : nil].compact
          end
        end
        def new_tags
          [:instance,{:name => 'tags',:url => "#{url}tags", :new_rec => true, :schema => [['number','message_id',RESTRICT_HIDE,id],['text','tags',RESTRICT_REQ]]}]
        end
        def new_user_tags
          [:instance,{:name => 'user_tags',:url => "#{url}user_tags", :new_rec => true, :schema => [['number','user_tags[message_id]',RESTRICT_HIDE,id],['text','user_tags[tags]',RESTRICT_REQ]]}]
        end
        def add_tags(tags,user=nil)
          if respond_to?(:public_tags)
            tags.to_s.split(',').each {|tag| add_public_tag(PublicTag.find_or_create(:tag => tag))}
          else
            add_user_tags(tags,user)
          end
        end
        def add_user_tags(tags,user=nil) #does not conflict with add_user_tag
          user||=$request[:user][:id]
          if user.class==String
            user.split(',').each {|u| add_user_tags(tags,User[:name => u][:id])}
          elsif user.class==Array
            user.each {|u| add_user_tags(tags,u)}
          elsif user.class==Fixnum
            tags.to_s.split(',').each {|tag| add_user_tag(UserTag.find_or_create(:user_id => user, :tag => tag))}
          end
        end
      end
      module PublicTaggingMethods
      end
      module UserTaggingMethods
      def after_create
        if respond_to?(:user_tags)
          add_user_tags("inbox,#{tags}",recipients)
          add_user_tags("sent,#{recipients.match(/\b#{author.name}\b/) ? '' : tags}",author_id)
        end
      end
      end
      def self.tagging_for(klass, user_class=nil,join_table=nil)
        current_user_tags=Module.new do
            def current_user_tags
              filter(:tags__user_id => $request[:user][:id])
            end
          end
        tagged_class=Resources.const_get(klass.to_sym)
        join_table||=:"#{tagged_class.table_name}_tags"
        klass_key=:"#{tagged_class.table_name.to_s.singularize}_id"
        tag_key=:tag_id
        attr_accessor klass_key
        if user_class
          UserTag.many_to_many klass.to_sym, :join_table => join_table,:left_key => tag_key,:right_key => klass_key,:extend => current_user_tags
          tagged_class.many_to_many :user_tags,:join_table => join_table,:left_key => klass_key,:right_key => tag_key, :extend => current_user_tags
          Resources.const_get(user_class).one_to_many :user_tags
          UserTag.many_to_one Resources.const_get(user_class).name.underscore.to_sym
        else
          PublicTag.many_to_many klass.to_sym, :join_table => join_table,:left_key => tag_key,:right_key => klass_key
          tagged_class.many_to_many :public_tags,:join_table => join_table,:left_key => klass_key,:right_key => tag_key
        end
      end
      def validate
        validates_presence :tag
        validates_unique [:tag,:user_id]
      end
      def before_save
        super
        self.tag.downcase!
        self.tag.strip!
      end
      def after_save
        super
        assoc=methods.grep(/_id=$/) - ['user_id=']
        assoc.each do |a|
          if c=self.send(a.sub(/=$/,''))
            send "add_#{a.sub(/_id=/,'')}", Marley::Resources.const_get(a.sub(/_id=/,'').camelize.to_sym)[c]
          end
        end
      end
    end
    class PublicTag < Tag
      set_dataset DB[:tags].filter(:user_id => nil)
    end
    class UserTag < Tag
      set_dataset DB[:tags].filter(~{:user_id => nil})
    end
  end
end
