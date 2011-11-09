
RESTRICT_HIDE=1
RESTRICT_RO=2
RESTRICT_REQ=4
TYPE_INDEX=0
NAME_INDEX=1
RESTRICTIONS_INDEX=2
module Sequel::Plugins::RestConvenience
  module ClassMethods
    def controller
      Marley::ModelController.new(self)
    end
    def resource_name
      self.name.sub(/.*::/,'').underscore
    end
    def reggae_link(action=nil)
      [:link,{:url => "/#{self.resource_name}/#{action}",:title => "#{action.humanize} #{self.resource_name.humanize}".strip}]
    end
    def list(params=nil)
      user=$request[:user]
      if user.respond_to?(otm=self.resource_name.pluralize)
        if user.method(otm).arity==0  
          if (relationship=user.send(otm)).respond_to?(:filter)
            relationship.filter($request[:get_params][resource_name.to_sym])
          else
            user.send(otm)
          end
        else
          user.send(otm,$request[:get_params][resource_name.to_sym])
        end
      else
        raise Marley::AuthorizationError
      end
    end
    def autocomplete(input_content)
      filter(:name.like("#{input_content.strip}%")).map {|rec| [rec.id, rec.name]}
    end
  end
  module InstanceMethods
    def get_actions; [];end
    def edit; self; end
    def rest_cols
      columns.reject do |c| 
        if new?
          c.to_s.match(/(^id$)|(_type$)|(date_(created|updated))/)
        else
          c.to_s.match(/_type$/)
        end
      end
    end
    def hidden_cols
      columns.select {|c| c.to_s.match(/(_id$)/)}
    end
    def write_cols
      rest_cols.reject {|c| c.to_s.match(/(^id$)|(date_(created|updated))/)}
    end
    def required_cols;[];end
    def rest_schema
      rest_cols.map do |col_name|
        db_spec=db_schema.to_hash[col_name]
        col_type=db_spec ? db_spec[:db_type].downcase : col_name
        restrictions=0
        restrictions|=RESTRICT_HIDE if hidden_cols.include?(col_name)
        restrictions|=RESTRICT_RO unless write_cols.include?(col_name)
        restrictions|=RESTRICT_REQ if required_cols.include?(col_name) || (db_spec && !db_spec[:allow_null])
        [col_type, col_name, restrictions,send(col_name)]
      end
    end
    def to_s
      respond_to?('name') ? name : id.to_s
    end
    def to_a
      a=Marley::ReggaeInstance.new([ {:name => self.class.resource_name,:url => url ,:new_rec => self.new?,:schema => rest_schema,:get_actions => get_actions}])
      if respond_to?(:rest_associations) && ! new?
        a.contents=rest_associations.map do |assoc|
          (assoc.class==Symbol ? send(assoc) : assoc).map{|instance| instance.to_a}
        end
      end
      a
    end
    def to_json
      to_a.to_json
    end
    def url(action=nil)
      "/#{self.class.resource_name}/#{self[:id]}/#{action}".sub('//','/')
    end
    def reggae_link(action=nil)
      [:link,{:url => url,:title => "#{action.humanize}"}]
    end
  end
end
