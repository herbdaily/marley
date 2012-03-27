module Marley
  module Plugins
    class Tagging < Plugin
      @default_opts={:concat_tags => true}
      def apply(*klasses)
        klasses.each do |klass|
          klass=MR.const_get(klass) if klass.is_a?(String)

          klass.derived_after_cols![:new?][:all] << @tag_col_name.to_sym
          klass.extend @class_methods_mod
          @instance_methods_mod.send(:append_features,klass)
          Marley::Utils.many_to_many_join(klass, @tag_class)
        end
      end
      def initialize(opts={})
        super
        tag_type=@tag_type=@opts[:tag_type]
        tag_col_name=@tag_col_name="_#{@tag_type}_tags"
        tag_class=@tag_class=MR.const_get(@tag_col_name.sub(/^_/,'').singularize.camelcase)
        tags_ds_name=@tags_ds_name="#{tag_col_name.sub(/^_/,'')}_dataset"
        @class_methods_mod=Module.new do |m|
          define_method(:list_dataset) {|*args|
            super.eager_graph(tag_class.resource_name.pluralize.to_sym => proc{|ds| ds.filter(:tags__user_id => tag_class.associations.include?(:user) ? current_user[:id] : nil)})
          }
        end
        @instance_methods_mod=Module.new do |m|
          attr_writer tag_col_name
          define_method(:write_cols) {
            super << tag_col_name.to_sym
          }

          
          define_method("#{tag_col_name}_ds".to_sym) { #e.g. _private_tags_ds
            send(tags_ds_name).filter({:tags__user_id => (tag_class.associations.include?(:user) ? self.class.current_user[:id] : nil)})
          }
          define_method(tag_col_name.to_sym) {    #e.g. _private_tags
            #send("#{tag_col_name}_ds").map {|t| t.tag}.join(', ') unless new?
             send(tag_class.resource_name.pluralize.to_sym).map {|t| t.tag}.join(', ') unless new?
          }
          define_method("add#{tag_col_name}".to_sym) {|tags|  #e.g. add_private_tags
            vals_hash={:user_id => (tag_class.associations.include?(:user) ? self.class.current_user[:id] : nil)}
            tags.to_s.split(',').each {|tag| self.send("add#{tag_col_name.singularize}",tag_class.find_or_create(vals_hash.update(:tag => tag))) }
          }
          define_method("replace#{tag_col_name}".to_sym) {  #e.g. replace_private_tags
            send("#{tag_col_name}_ds").each {|tag| send("remove#{tag_col_name}".singularize,tag)}
            send("add#{tag_col_name}",instance_variable_get("@#{tag_col_name}"))
          }
          define_method(:after_save) {
            super
            methods.select {|m| m.match(/^replace_.+_tags/)}.each do |replace_method|
              send(replace_method)
            end
          }
        end
      end
    end
  end
  module Joints
    class Tags < Joint
      module Resources
        class Tag < Sequel::Model
          sti
          def self.list_dataset(params={})
            dataset.order(:tag)
          end
          def validate
            validates_presence :tag
            validates_unique [:tag,:user_id]
          end
          def actions(parent_instance)
            {:delete => "#{parent_instance ? parent_instance.url : ''}#{url}"}
          end
          def before_save
            super
            self.tag.downcase!
            self.tag.strip!
          end
        end
        class PublicTag < Tag
          @owner_col=nil
        end
        class PrivateTag < Tag
          MR::User.join_to(self) if MR::User
          def self.list_dataset(params={})
            current_user_ds.order(:tag)
          end
        end
      end
    end
  end
end
