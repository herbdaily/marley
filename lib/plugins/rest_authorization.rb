
module Marley
  module Plugins
    class RestAuthorization < Plugin
      def apply(klass)
        super
      end
      module ClassMethods
        attr_accessor :owner_col, :allowed_get_methods
        def inherited(c)
          super
          c.owner_col=@owner_col
          c.allowed_get_methods=@allowed_get_methods
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
              new($request[:post_params][resource_name.to_sym]||{}).current_user_role=='owner' && meth.nil?
            when 'rest_get'
              methods=@allowed_get_methods || ['section','list','new']
              (methods.class==Hash ? methods[$request[:user].class] : methods).include?(meth)
            end
          end
        end
      end
      module InstanceMethods
        def after_initialize
          super
          send("#{self.class.owner_col}=",$request[:user][:id]) if $request && self.class.owner_col && new?
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
  end
end
