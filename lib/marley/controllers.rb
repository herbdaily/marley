module Marley
  # Translates REST URL's into ORM calls to the model class with which it is initialized.
  class ModelController
    def initialize(model)
      @model=model
      if $request[:path][1].to_s.match(/^\d+$/) #references a specific instance by ID
        @instance=@model.list_dataset(:"#{@model.table_name}__id" => $request[:path][1].to_i).all[0]
        raise RoutingError unless @instance
        @method_name=$request[:path][2].sub(/[\?\&\+]$/,'') rescue nil #ditch trailing characters, if any
        if @method_name
          raise RoutingError unless @instance.respond_to?(@method_name)
          @method=@instance.method(@method_name)
        end
      else #class method -- should yield 0 or more instances of model in an array
        @method_name=$request[:path][1].sub(/[\?\&\+]$/,'') rescue nil #ditch trailing characters, if any 
        @method_name='list' if @method_name.nil? && $request[:verb]=='rest_get'
        if @method_name
          raise RoutingError unless @model.respond_to?(@method_name)
          @method=@model.method(@method_name)
        end
      end
      if (a=@instance || @model).requires_user?
        raise AuthorizationError unless a.authorize(@method_name)
      end
      if @method && $request[:verb] != 'rest_post'
        @instances=if p=$request[:get_params][@model.resource_name.to_sym] 
                     @method.call(p) 
                   elsif i=$request[:path][3]
                     @method.call[i.to_i]
                   else 
                     @method.call
                   end 
      end
    end
    def rest_get; @instances || @instance; end
    def rest_post
      if @instance
        raise RoutingError unless @method
        params=$request[:post_params][@method_name.to_sym] || $request[:post_params][@model.resource_name.to_sym][@method_name.to_sym] 
        raise ValidationFailed unless params
        params=[params] unless params.class==Array
        params.map do |param|
          @instance.send("add_#{@method_name}",param)
        end
      else
        params=($request[:post_params][@model.resource_name.to_sym]||{})
        @instance=@model.new(params.reject {|k,v| v.nil?}) #reject nils to work around sequel validation flaw
        raise AuthorizationError if params.keys.find {|k| ! @instance.write_cols.include?(k) }
        params.keys.each {|k| @instance.send("#{k.to_s}=",params[k]) if k.to_s.match(/^_/)}
        @instance.save
        @instance.respond_to?('create_msg') ? @instance.create_msg : @instance
      end
    end
    def rest_put
      raise RoutingError unless @instance
      params=($request[:post_params][@model.resource_name.to_sym]||{})
      raise AuthorizationError if params.keys.find {|k| ! @instance.write_cols.include?(k) }
      params.keys.each {|k| @instance.send("#{k.to_s}=",params[k]) if k.to_s.match(/^_/)}
      @instance.modified!
      @instance.update_only(params,@instance.write_cols)
    end
    def rest_delete
      raise RoutingError unless @instance
      if @instances
        @instances.each do |instance|
          meth="remove_#{instance.class}"
          raise RoutingError unless @instance.respond_to?(meth)
          @instance.send(meth,instance)
        end
      else
        @instance.destroy
      end
    end
  end
end
