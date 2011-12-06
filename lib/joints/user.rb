require 'digest/sha1'
Sequel::Model.plugin :validation_helpers
module Marley
  module Plugins
    class CurrentUserMethods < Plugin
      @default_opts={:join_type => 'many_to_one'}
      def apply(*klasses)
        super(klasses)
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
        def list(params={})
          current_user_ds.filter(params).all
        end
      end
    end
  end
  module Joints
    def smoke(opts)
      super
    end
    class User < Joint
      LOGIN_FORM= [:instance,{:url => 'login',:description => 'Existing users please log in here:',:new_rec => true,:schema => [[:text,'name',RESTRICT_REQ],[:password,'password',RESTRICT_REQ]]}]
      module Resources
        class User < Sequel::Model
          set_dataset :users
          sti
          attr_accessor :old_password,:password, :confirm_password
          @allowed_get_methods=['new']
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
