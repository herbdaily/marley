

module Marley
  module Plugins
    class OrmRestConvenience < Plugin
      @default_opts={:additional_extensions => [Marley::Utils.class_attributes(:model_actions,{:get => [:new]}), Marley::Utils.class_attributes(:instance_actions)]}
      module ClassMethods
        def controller; Marley::ModelController.new(self); end
        # the next 2 will have to be overridden for most applications
        def authorize(verb); true ; end
        def requires_user?; false; end
        def resource_name; self.name.sub(/.*::/,'').underscore; end
        def foreign_key_name; :"#{(respond_to?(:table_name) ? table_name : resource_name).to_s.singularize}_id"; end
        def list(params={})
          if respond_to?(:list_dataset)
            list_dataset.filter(params).all
          else
            filter(params).all
          end
        end
        def actions; @model_actions.respond_to?(:retrieve) ? @model_actions.retrieve : @model_actions; end
        def reggae_link(action='')
          [:link,{:url => "/#{self.resource_name}/#{action}",:title => "#{action.humanize} #{self.resource_name.humanize}".strip}]
        end
        def sti
          plugin :single_table_inheritance, :"#{self.to_s.sub(/.*::/,'').underscore}_type", :model_map => lambda{|v| MR.const_get(v.to_sym)}, :key_map => lambda{|klass|klass.name.sub(/.*::/,'')}
        end
      end
      module InstanceMethods
        def edit; self; end
        def rest_associations;[];end
        # the next 2 will have to be overridden for most applications
        def authorize(verb); true ; end
        def requires_user?; false; end
        def rest_cols 
          columns.reject do |c| 
            if new?
              c.to_s.match(/(^id$)|(_type$)|(date_(created|updated))/)
            else
              c.to_s.match(/_type$/)
            end
          end
        end
        def hidden_cols; columns.select {|c| c.to_s.match(/(_id$)/)}; end
        def write_cols; rest_cols.reject {|c| c.to_s.match(/(^id$)|(date_(created|updated))/)}; end
        def required_cols;[];end

        def actions(parent_instance=nil)
          respond_to?(:instance_actions) ? instance_actions(parent_instance) : self.class.instance_actions
        end

        def reggae_schema
          Marley::ReggaeSchema.new(
          rest_cols.map do |col_name|
            db_spec=db_schema.to_hash[col_name]
            col_type=db_spec ? db_spec[:db_type].downcase : col_name
            restrictions=0
            restrictions|=RESTRICT_HIDE if hidden_cols.include?(col_name)
            restrictions|=RESTRICT_RO unless write_cols.include?(col_name)
            restrictions|=RESTRICT_REQ if required_cols.include?(col_name) || (db_spec && !db_spec[:allow_null])
            [col_type, col_name, restrictions,send(col_name)]
          end)
        end
        def to_s
          respond_to?('name') ? name : id.to_s
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
          [:link,{:url => url,:title => "#{action.humanize}"}]
        end
      end
    end
  end
end
