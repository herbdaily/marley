module Marley
  class ModelController
    def initialize(model)
      @model=model
      if $request[:path][1].to_s.match(/^\d+$/) #references a specific instance by ID
        @instance=@model[$request[:path][1].to_i]
        @method_name=$request[:path][2]  
        if @method_name
          raise RoutingError.new(@model,@instance,@method_name) unless @instance.respond_to?(@method_name)
          @method=@instance.method(@method_name)
        end
      else #class method -- should yield 0 or more instances of model in an array
        @method_name=$request[:path][1] 
        @method_name='list' if @method_name.nil? && $request[:verb]=='rest_get'
        if @method_name
          raise RoutingError.new(@model,@instance,@method_name) unless @model.respond_to?(@method_name)
          @method=@model.method(@method_name)
        end
      end
      if (a=@instance || @model).requires_user?
        raise AuthorizationError unless a.authorize(@method_name)
      end
      if @method && $request[:verb] != 'rest_post'
        @instances=if p=$request[:get_params][@model.resource_name.to_sym]
          @method.call(p) 
        else 
          @method.call
        end 
      end
    end
    def rest_get; @instances || @instance; end
    def rest_post
      if @instance
        raise RoutingError.new(@model,@instance,@method_name) unless @method
        params=$request[:post_params][@model.resource_name.to_sym][@method_name.to_sym] || $request[:post_params][@method_name.to_sym] 
        raise ValidationFailed unless params
        params=[params] unless params.class==Array
        params.map do |param|
          @instance.send("add_#{@method_name}",param)
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
