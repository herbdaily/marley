
module Marley
  def self.tagging_for(klass, opts={})
    Resources.const_get(klass.to_sym).many_to_many :tags
    Resources::Tag.many_to_many klass.to_sym
    join_class="#{klass}Tag"
    Resources.const_set(join_class.to_sym, Class.new(Sequel::Model))
    Resources.const_get(join_class.to_sym).set_dataset(join_class.underscore.pluralize.to_sym) #apparently this is necessary when declaring a Sequel::Model like this
    if opts[:user]
      Resources.const_get(opts[:user]).one_to_many :tags
      Resources::Tag.many_to_one Resources.const_get(opts[:user]).name.underscore.to_sym
    end
  end
  module Resources
    class Tag < Sequel::Model
      def validate
        validates_presence :tag
        validates_uniqueness [:tag,:user_id]
      end
      def json_uri
        [:uri, {:url => "/messages_tag/#{id}",:updatable => true,:deletable => true,:title => tag.tag.humanize}]
      end
      def after_initialize
        super
        self.tag.strip!
      end
      def before_save
        self.tag.downcase!
        self.tag.strip!
        self.tag=" #{tag}" if message.class==PrivateMessage && RESERVED_PM_TAGS.include?(self.tag)
        self.tag=" #{tag}" if message.class==Post && RESERVED_POST_TAGS.include?(self.tag)
      end
    end
  end
end
