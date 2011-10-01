
module Marley
  def self.tagging_for(klass, user_class=nil,join_table=nil)
    tagged_class=Resources.const_get(klass.to_sym)
    join_table||="#{tagged_class.table_name}_tags"
    klass_key="#{tagged_class.table_name.to_s.singularize}_id"
    if user_class
      Resources::UserTag.many_to_many klass.to_sym, :join_table => join_table,:left_key => 'tag_id',:right_key => klass_key
      tagged_class.many_to_many :user_tags,:join_table => join_table,:left_key => klass_key,:right_key => 'tag_id' 
      #tagged_class.many_to_many :user_tags,:join_table => join_table,:left_key => klass_key,:right_key => 'tag_id' ,:extend => Module.new  do
      #  def current_user_tags
      #    filter(:user_id => $request[:user][:id])
      #  end
      #end
      Resources.const_get(user_class).one_to_many :user_tags
      Resources::UserTag.many_to_one Resources.const_get(user_class).name.underscore.to_sym
    else
      Resources::PublicTag.many_to_many klass.to_sym, :join_table => join_table,:left_key => 'tag_id',:right_key => klass_key
      tagged_class.many_to_many :public_tags,:join_table => join_table,:left_key => klass_key,:right_key => 'tag_id' 
    end
  end
  module Resources
    class Tag < Sequel::Model
      def validate
        validates_presence :tag
        validates_unique [:tag,:user_id]
      end
      def before_save
        super
        self.tag.downcase!
        self.tag.strip!
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
