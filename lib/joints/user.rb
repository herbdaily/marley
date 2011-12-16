require 'digest/sha1'
Sequel::Model.plugin :validation_helpers
module Marley
  module Plugins
    class CurrentUserMethods < Plugin
      @default_opts={
        :join_type => 'many_to_one',
        :additional_extensions => 
          [
            Marley::Utils.class_attributes(:reject_cols,[]), 
            Marley::Utils.class_attributes(:ro_cols,nil)
          ]
      }
      
      def apply(*klasses)
        super
        klasses.each do |klass|
          join_type=@opts[:"#{klass}_join_type"] || @opts[:join_type]
          reciprocal_join=join_type.split('_').reverse.join('_')
          klass=MR.const_get(klass) if klass.class==String
          klass.owner_col='user_id'
          MR::User.send(reciprocal_join, klass.resource_name.to_sym, :class => klass)
          klass.send(join_type, :user, :class => MR::User)
        end
      end
      module ClassMethods
        def current_user_ds
          filter(@owner_col.to_sym => $request[:user][:id])
        end
      end
      module InstanceMethods
        #def write_cols
        #  current_user_role=='owner' && super || []
        #end
      end
    end
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
              new(($request[:post_params][resource_name.to_sym]||{}).reject {|k,v| v.nil?}).current_user_role=='owner' && meth.nil?
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
          "owner" if $request && owners.include?($request[:user])
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
  module Joints
    class User < Joint
      LOGIN_FORM= [:instance,{:link => 'login',:description => 'Existing users please log in here:',:new_rec => true,:schema => [[:text,'name',RESTRICT_REQ],[:password,'password',RESTRICT_REQ]]}]
      module Resources
        class User < Sequel::Model
          set_dataset :users
          sti
          attr_accessor :old_password,:password, :confirm_password
          @allowed_get_methods=['new']
          def current_user
            block_given? ?  yield $request[:user] : $request[:user]
          end
          def write_cols;super - [:pw_hash]+ [:password,:confirm_password,:old_password];end
          def self.requires_user?
            ! ($request[:verb]=='rest_post' || ($request[:verb]=='rest_get' && $request[:path][1]=='new'))
          end
          def reggae_schema
            schema=super.delete_if {|c| [:pw_hash,:description,:active].include?(c[NAME_INDEX])}
            schema.push([:password,:old_password,0]) unless new?
            schema.push([:password,:password ,new? ? RESTRICT_REQ : 0],[:password,:confirm_password,new? ? RESTRICT_REQ : 0])
            schema
          end
          def self.authenticate(credentials)
            u=find(:name => credentials[0], :pw_hash => Digest::SHA1.hexdigest(credentials[1]))
            u.respond_to?(:user_type) ? Marley::Resources.const_get(u[:user_type].to_sym)[u[:id]] : u
          end
          def validate
            super
            validates_presence [:name]
            validates_unique [:name]
            if self.new? || self.old_password.to_s + self.password.to_s + self.confirm_password.to_s > ''
              errors[:password]=['Password must contain at least 8 characters'] if self.password.to_s.length < 8
              errors[:confirm_password]=['Passwords do not match'] unless self.password==self.confirm_password
              errors[:old_password]=['Old Password Incorrect'] if !self.new? && Digest::SHA1.hexdigest(self.old_password.to_s) != self.pw_hash
            end
          end
          def before_save
            if self.new? || self.old_password.to_s + self.password.to_s + self.confirm_password.to_s > ''
              self.pw_hash=Digest::SHA1.hexdigest(self.password)
            end
          end
          def create_msg
            [[:msg,{:title => 'Success!'},"Your login, '#{self.name}', has been sucessfully created. You can now log in."]]
          end
        end
      end
    end
  end
end
