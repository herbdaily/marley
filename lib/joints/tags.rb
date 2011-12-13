module Marley
  module Plugins
    class Tagging < Plugin
      @default_opts={:join_type => 'many_to_many'}
      def apply(*klasses)
        super
        klasses.each do |klass|
          klass=MR.const_get(klass) if klass.class==String
          #tag_class=MR.const_get(@opts[:tag_class_name])
          tag_class=@tag_class
          join_type=@opts[:"#{klass}_join_type"] || @opts[:join_type]
          if join_type=='many_to_many'
            Marley::Utils.many_to_many_join(klass, tag_class)
          else
            reciprocal_join=join_type.split('_').reverse.join('_')
            tag_class.send(reciprocal_join.to_sym, klass.resource_name.pluralize.to_sym, {:class => klass})
            klass.send(join_type.to_sym, tag_class.resource_name.pluralize.to_sym, {:class => tag_class})
          end
        end
      end
      def initialize(opts={})
        super
        tag_type=@tag_type=@opts[:tag_type]
        tag_col_name=@tag_col_name="_#{@tag_type}_tags"
        tag_class=@tag_class=MR.const_get(@tag_col_name.sub(/^_/,'').singularize.camelcase)
        instance_methods_mod=Module.new do |m|
          attr_accessor tag_col_name
          define_method :rest_cols do 
            super << tag_col_name.to_sym
          end
          define_method("add#{tag_col_name}".to_sym) {|tags|  #e.g. add_private_tags
            tags.to_s.split(',').each {|tag| self.send("add#{tag_col_name.singularize}",tag_class.find_or_create(:user_id => $request[:user][:id], :tag => tag)) }
          }
          define_method(:after_save) {
            super
            send("remove_all#{tag_col_name}")
            send("add#{tag_col_name}",instance_variable_get("@#{tag_col_name}"))
          }
          define_method(tag_col_name.to_sym) {
            send(tag_col_name.sub(/^_/,'')).map {|t| t.tag}.join(', ')
          }
        end
        self.class.const_set :InstanceMethods,instance_methods_mod

      end
    end
  end
  module Joints
    class Tags < Joint
      module Resources
        class Tag < Sequel::Model
          def validate
            validates_presence :tag
            validates_unique [:tag,:user_id]
          end
          def instance_actions(parent_instance)
            {:delete => "#{parent_instance ? parent_instance.url : ''}#{url}"}
          end
          def before_save
            super
            self.tag.downcase!
            self.tag.strip!
          end
        end
        class PublicTag < Tag
          set_dataset DB[:tags].filter(:user_id => nil).order(:tag)
        end
        class PrivateTag < Tag
          Marley.plugin('current_user_methods').apply(self)
          def self.list_dataset
            current_user_dataset.order(:tag)
          end
        end
      end
    end
  end
end
