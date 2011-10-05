
module Marley
  module Resources
    class Tag < Sequel::Model
      def self.tagging_for(klass, user_class=nil,join_table=nil)
        tagged_class=Resources.const_get(klass.to_sym)
        join_table||="#{tagged_class.table_name}_tags"
        klass_key=:"#{tagged_class.table_name.to_s.singularize}_id"
        tag_key=:tag_id
        attr_accessor klass_key
        if user_class
          many_to_many klass.to_sym, :join_table => join_table,:left_key => tag_key,:right_key => klass_key
          tagged_class.many_to_many :user_tags,:join_table => join_table,:left_key => klass_key,:right_key => tag_key 

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
