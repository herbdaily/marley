module Marley
  module Plugins
    class OrmRestConvenience < Plugin
      #next 3 must go
      Sequel::Model.plugin :validation_helpers
      Sequel::Plugins::ValidationHelpers::DEFAULT_OPTIONS.merge!(:presence => {:message => 'is required'})
      Sequel::Model.plugin :timestamps, :create => :date_created, :update => :date_updated

      @default_opts={
        :required_plugins => [:rest_convenience],
        :class_attrs =>[ [:model_actions,{:get => [:new, :list]}] ],
        :lazy_class_attrs =>  [ :new?,
          [:instance_actions,{:all => nil}],
          [:derived_before_cols,{:all => []}],
          [:derived_after_cols,{:all => []}],
          [:reject_cols,{true => [/^id$/,/_type$/,/date_(created|updated)/], false => [/_type$/]}],
          [:ro_cols,{true => [/^id$/,/_id$/], false => [/^id$/,/_id$/,/date_(created|updated)/]}],
          [:hidden_cols,{:all => [/_id$/]}],
          [:required_cols,{:all => []}] ]
      }
      module ClassMethods
        def controller; Marley::ModelController.new(self); end
        # the next 2 will have to be overridden for most applications
        def authorize(verb); send_or_default("authorize_#{verb}",true) ; end
        def requires_user?; false; end

        def foreign_key_name; :"#{(respond_to?(:table_name) ? table_name : resource_name).to_s.singularize}_id"; end

        def list_dataset(params={})
          dataset.filter(params)
        end
        def list(params={})
          list_dataset(params).all
        end
        def reggae_instance_list(params={})
          items=list(params)
          if items.length==0
            Marley::ReggaeMessage.new(:title => 'Nothing Found')
          else
            cols=items[0].rest_cols
            Marley::ReggaeInstanceList.new(
              :name => resource_name,
              :schema => items[0].reggae_schema(true),
              :items => items.map{|i| cols.map{|c|i.send(c)}}
            )
          end
        end
        def sti
          plugin :single_table_inheritance, :"#{self.to_s.sub(/.*::/,'').underscore}_type", :model_map => lambda{|v| MR.const_get(v.to_sym)}, :key_map => lambda{|klass|klass.name.sub(/.*::/,'')}
        end
      end
      module InstanceMethods
        # the next 2 will have to be overridden for most applications
        def authorize(verb); true ; end
        def requires_user?; false; end
          
        def col_mods_match(mod_type); lambda {|c| c.to_s.match(Regexp.union(send(:"_#{mod_type}")))}; end

        def rest_cols; _derived_before_cols.to_a + (columns.reject &col_mods_match(:reject_cols)) + _derived_after_cols.to_a;end
        def write_cols; rest_cols.reject &col_mods_match(:ro_cols);end
        def hidden_cols; rest_cols.select &col_mods_match(:hidden_cols);end
        def required_cols; rest_cols.select &col_mods_match(:required_cols);end
        def actions(parent_instance=nil); _instance_actions; end

        def rest_associations;[];end

        def reggae_schema(list_schema=false)
          Marley::ReggaeSchema.new(
            rest_cols.map do |col_name|
              db_spec=db_schema.to_hash[col_name]
              col_type=db_spec ? db_spec[:db_type].downcase : "text"
              col_type=:password if col_name.to_s.match(/password/)
              if list_schema
                restrictions=RESTRICT_RO
                restrictions|=RESTRICT_HIDE if hidden_cols.include?(col_name)
                [col_type, col_name, restrictions]
              else
                restrictions=0
                restrictions|=RESTRICT_HIDE if hidden_cols.include?(col_name)
                restrictions|=RESTRICT_RO unless write_cols.include?(col_name)
                restrictions|=RESTRICT_REQ if required_cols.include?(col_name) || (db_spec && !db_spec[:allow_null])
                [col_type, col_name, restrictions,send(col_name)]
              end
            end 
          )
        end
        def to_s
          respond_to?('name') ? name : "#{self.class.name} #{id.to_s}"
        end
        def reggae_instance(parent_instance=nil)
          a=Marley::ReggaeInstance.new( 
            {:name => self.class.resource_name,:url => url ,:new_rec => self.new?,:schema => reggae_schema,:actions => self.actions(parent_instance)}
          )
          a.contents=rest_associations.to_a.map do |assoc|
            assoc.map{|instance|  instance.reggae_instance(self)} 
          end unless new?
          a
        end
        def to_json(*args)
          reggae_instance.to_json
        end
        def url(action=nil)
          "/#{self.class.resource_name}/#{self[:id]}/#{action}".sub(/\/$/,'')
        end
        def reggae_link(action='')
          ReggaeLink.new({:url => url,:title => "#{action.humanize}"})
        end
      end
    end
  end
end
