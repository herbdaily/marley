require 'digest/sha1'
LOGIN_FORM= [:instance,{:resource => 'login',:description => 'Existing users please log in here:',:new_rec => true,:schema => [[:text,'name',RESTRICT_REQ],[:password,'password',RESTRICT_REQ]]}]
module Marley
  module Resources
    module Menu
      def self.rest_get
        [[:menu,$request[:user].send("#{$request[:path].to_a[1] ? $request[:path][1] : 'main'}_menu")]]
      end
      def self.requires_user?
        ! ($request[:verb]=='rest_get' && $request[:path].nil?)
      end
    end
    class User < Sequel::Model
      attr_accessor :old_password,:password, :confirm_password
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
        find(:name => credentials[0], :pw_hash => Digest::SHA1.hexdigest(credentials[1]))
      end
      def validate
        validates_presence [:name]
        validates_unique [:name]
        validates_unique [:email] if respond_to?(:email)
      end
      def before_create
        super
        user_type='User'
      end
      def before_save
        if self.new? || self.old_password.to_s + self.pw.to_s + self.pw_confirm.to_s > ''
          errors[:password]=['Password must contain at least 8 characters'] if self.password.to_s.length < 8
          errors[:confirm_password]=['Passwords do not match'] unless self.password==self.confirm_password
          errors[:old_password]=['Old Password Incorrect'] if !self.new? && Digest::SHA1.hexdigest(self.old_password.to_s) != self.pw_hash
          raise Sequel::ValidationFailed.new(errors) if errors.length>0
          self.pw_hash=Digest::SHA1.hexdigest(self.password)
        end
      end
      def create_msg
        [[:msg,{:title => 'Success!'},"Your login, '#{self.name}', has been sucessfully created. You can now log in."]]
      end
      def main_menu
        app_name=$request[:opts][:app_name]
        if new?
          u=User.new.to_a
          u[1].merge!({:description => 'If you don\'t already have an account, please create one here:'})
          { :title => "Welcome to #{app_name}",
          :name => 'signup',
          :description => 'Login or signup here.',
          :items => [LOGIN_FORM,u] }
        else
          { :title => 'Main Menu',
          :name => 'main',
          :description => "Welcome to #{app_name}, #{$request[:user][:name]}",
          :items => [ [:resource,{:url => '/menu/private_messages',:title => 'Private Messages'}], [:resource,{:url => '/menu/public_messages',:title => 'Public Messages'}] ] }
        end
      end
    end
  end
end
