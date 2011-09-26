
module Marley
  def self.tagging_for(klass, user_class=nil)
    tagged_class=Resources.const_get(klass.to_sym)
    join_table="#{tagged_class.table_name}_tags"
    if user_class
      Resources::UserTag.many_to_many klass.to_sym, :join_table => join_table
      tagged_class.many_to_many :user_tags
      Resources.const_get(user_class).one_to_many :user_tags
      Resources::UserTag.many_to_one Resources.const_get(user_class).name.underscore.to_sym
    else
      Resources::PublicTag.many_to_many klass.to_sym, :join_table => join_table
      tagged_class.many_to_many :public_tags
    end
  end
  module Resources
    class Tag < Sequel::Model
      plugin :single_table_inheritance, :user_id, :model_map => lambda{|v| v.nil? ? :PublicTag : :UserTag}
      def validate
        validates_presence :tag
        validates_uniqueness [:tag,:user_id,:tag_type]
      end
      def json_uri
        [:uri, {:url => "/#{self.class.name.underscore}/#{id}",:updatable => true,:deletable => true,:title => tag.humanize}]
      end
      def after_initialize
        super
        self.tag.strip!
      end
      def before_save
        super
        self.tag.downcase!
        self.tag.strip!
      end
    end
    class PublicTag < Tag
    end
    class UserTag < Tag
      def before_create
        user_id=$request[:user][:id]
      end
    end
  end
end
