require 'digest/sha1'
LOGIN_FORM= [:instance,{:url => 'login',:description => 'Existing users please log in here:',:new_rec => true,:schema => [[:text,'name',RESTRICT_REQ],[:password,'password',RESTRICT_REQ]]}]
module Marley
  module Joints
    class BasicUser < Joint
      module Resources
        class BasicUser < Sequel::Model
          set_dataset :users
          plugin :single_table_inheritance, :user_type, :model_map => lambda{|v| MR.const_get(v.to_sym)}, :key_map => lambda{|klass|klass.name.sub(/.*::/,'')}
          attr_reader :menus
          attr_accessor :old_password,:password, :confirm_password
          def write_cols;[:name,:email,:password,:confirm_password,:old_password];end
          def rest_schema
            schema=super.delete_if {|c| c[NAME_INDEX]==:pw_hash || c[NAME_INDEX]==:description}
            schema.push([:old_password,:password,0]) unless new?
            schema.push([:password,:password,new? ? RESTRICT_REQ : 0],[:password,:confirm_password,new? ? RESTRICT_REQ : 0])
            schema
          end
          def self.requires_user?
            ! ($request[:verb]=='rest_post')
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
