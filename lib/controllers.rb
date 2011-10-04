module Marley
  class ModelController
    def initialize(model)
      @model=model
      if $request[:path][1].to_s.match(/^\d+$/) #references a specific instance by ID
        @instance=@model[$request[:path][1].to_i]
        @method=$request[:path][2]  
        if @method
          raise RoutingError.new(@model,@instance,@method) unless @instance.respond_to?(@method)
          method=@instance.method(@method)
        end
      else #class method -- should yield 0 or more instances of model in an array
        @method=$request[:path][1] 
        @method='list' if @method.nil? && $request[:verb]=='rest_get'
        if @method
          raise RoutingError.new(@model,@instance,@method) unless @model.respond_to?(@method)
          method=@model.method(@method)
        end
      end
      if (a=@instance || @model).requires_user?
        raise AuthorizationError unless a.authorize(@method)
      end
      if method
        @instances=if p=$request[:get_params][@model.to_s.sub(/.*::/,'').underscore.to_sym]
          method.call(p) 
        else 
          method.call
        end 
      end
    end
    def rest_get; @instances || @instance; end
    def rest_post
      if @instance
        raise RoutingError.new(@model,@instance,@method) unless (@instances && p=$request[:post_params][@model.resource_name][@method])
        p=[p] unless p.class==Array
        p.map do |i|
          @newinstance=@model.send("add_#{@method}",i)
          @newinstance.save(@newinstance.write_cols)
          @instances << @newinstance
        end
      else
        @instance=@model.new($request[:post_params][@model.resource_name.to_sym] || {})
        @instance.save(@instance.write_cols)
        @instance.respond_to?('create_msg') ? @instance.create_msg : @instance
      end
    end
    def rest_put
      raise RoutingError(@model) unless @instance
      (@instances || [@instance]).map do |i|
        i.modified!
        i.update_only($request[:post_params][@model.resource_name.to_sym],i.write_cols)
      end
    end
    def rest_delete
      raise RoutingError(@model) unless @instance
      (@instances || [@instance]).each {|i| i.destroy}
    end
  end
end
