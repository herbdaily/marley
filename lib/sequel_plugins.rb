RESTRICT_HIDE=1
RESTRICT_RO=2
RESTRICT_REQ=4
TYPE_INDEX=0
NAME_INDEX=1
RESTRICTIONS_INDEX=2
module Sequel::Plugins::RestConvenience
  module ClassMethods
    attr_accessor :instance_get_actions
    def controller
      Marley::ModelController.new(self)
    end
    def resource
      self.name.sub(/.*::/,'').underscore
    end
    def json_resource(action=nil)
      [:resource,{:url => "/#{self.resource}/#{action}",:title => "#{action.humanize} #{self.resource.humanize}".strip}]
    end
    def list(params=nil)
      if $request[:user].respond_to?(otm=self.resource.pluralize)
        $request[:user].send(otm,$request[:get_params][resource.to_sym])
      else
        raise Marley::AuthorizationError
      end
    end
    def autocomplete(input_content)
      filter(:name.like("#{input_content.strip}%")).map {|rec| [rec.id, rec.name]}
    end
  end
  module InstanceMethods
    def edit; self; end
    def rest_cols
      columns.reject do |c| 
        if new?
          c.to_s.match(/(^id$)|(^active$)|(_type$)|(date_(created|updated))/)
        else
          c.to_s.match(/_type$/)
        end
      end
    end
    def hidden_cols;[];end
    def write_cols
      rest_cols.reject {|c| c.to_s.match(/(^id$)|(date_(created|updated))/)}
    end
    def required_cols;[];end
    def rest_schema
      rest_cols.map do |col_name|
        db_spec=db_schema.to_hash[col_name]
        if a=self.class.association_reflections[col_name.to_s.sub(/_id$/,'').to_sym]
          col_type=a[:type]
        else
          col_type=db_spec ? db_spec[:db_type].downcase : col_name
        end
        restrictions=0
        restrictions|=RESTRICT_HIDE if hidden_cols.include?(col_name)
        restrictions|=RESTRICT_RO unless write_cols.include?(col_name)
        restrictions|=RESTRICT_REQ if required_cols.include?(col_name) || (db_spec && !db_spec[:allow_null])
        val=col_type==:many_to_one ? [values[col_name],send(col_name.to_s.sub(/_id$/,'')).to_s] : send(col_name)
        [col_type, col_name, restrictions,val]
      end.compact
    end
    def to_s
      respond_to?('name') ? name : id.to_s
    end
    def to_a
      [:instance, {:resource => self.class.resource ,:new_rec => self.new?,:schema => rest_schema,:instance_get_actions => self.class.instance_get_actions}]
    end
    def to_json
      to_a.to_json
    end
    def json_resource(action=nil)
      [:resource,{:url => "/#{self.class.resource}/#{self[:id]}/#{action}",:title => "#{action.humanize}"}]
    end
  end
end
module Sequel::Plugins::RestAuthorization
  module ClassMethods
    attr_accessor :owner_col
    def inherited(c)
      super
      c.owner_col=@owner_col
    end
    def requires_user?(verb=nil,meth=nil);true;end
    def authorize(meth)
      if respond_to?(auth_type="authorize_#{$request[:verb]}")
        send(auth_type,meth)
      else
        case $request[:verb]
        when 'rest_put','rest_delete'
          false 
        when 'rest_post'
          new($request[:post_params][resource.to_sym]).current_user_role=='owner' && meth.nil?
        when 'rest_get'
          meth=='list'||meth=='new'
        end
      end
    end
  end
  module InstanceMethods
    def after_initialize
      send("#{self.class.owner_col}=",self.class.user[:id]) if self.class.owner_col && new?
    end
    def requires_user?(verb=nil,meth=nil);true;end
    def authorize(meth)
      if respond_to?(auth_type="authorize_#{$request[:verb]}")
        send(auth_type,meth)
      else
        current_user_role=='owner'
      end
    end
    def current_user_role
      "owner" if owners.include?($request[:user])
    end
    def owners
      if self.class.to_s.match(/User$/)||self.class.superclass.to_s.match(/User$/)
        [self]
      elsif @owner_col
        [User[send(@owner_col)]]
      else
        self.class.association_reflections.select {|k,v| v[:type]==:many_to_one}.map {|a| self.send(a[0]) && self.send(a[0]).owners}.flatten.compact
      end
    end
  end
end

