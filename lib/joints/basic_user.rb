require 'digest/sha1'
LOGIN_FORM= [:instance,{:uri => 'login',:description => 'Existing users please log in here:',:new_rec => true,:schema => [[:text,'name',RESTRICT_REQ],[:password,'password',RESTRICT_REQ]]}]
module Marley
  module Resources
    class Menu
      attr_accessor :title,:name,:description, :items
      def self.rest_get
        $request[:user].menu($request[:path].to_a[1])
      end
      def self.requires_user?
        ! ($request[:verb]=='rest_get' && $request[:path].nil?)
      end
      def initialize(*args)
        @title,@description,@items=args
      end
      def to_json
        [:menu,{:title => @title,:description => @description,:items => @items}]
      end
    end
    class BasicUser < Sequel::Model
      set_dataset :users
      attr_reader :menus
      attr_accessor :old_password,:password, :confirm_password
      def initialize(*args)
        super
        u=to_a
        u[1].merge!({:description => 'If you don\'t already have an account, please create one here:'})
        @menus={:main => Menu.new("Welcome to #{$request[:opts][:app_name]}",'Login or signup here.',[LOGIN_FORM,u])}
      end
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
        super
        validates_presence [:name]
        validates_unique [:name]
        if self.new? || self.old_password.to_s + self.pw.to_s + self.pw_confirm.to_s > ''
          errors[:password]=['Password must contain at least 8 characters'] if self.password.to_s.length < 8
          errors[:confirm_password]=['Passwords do not match'] unless self.password==self.confirm_password
          errors[:old_password]=['Old Password Incorrect'] if !self.new? && Digest::SHA1.hexdigest(self.old_password.to_s) != self.pw_hash
        end
      end
      def before_save
        if self.new? || self.old_password.to_s + self.pw.to_s + self.pw_confirm.to_s > ''
          self.pw_hash=Digest::SHA1.hexdigest(self.password)
        end
      end
      def create_msg
        [[:msg,{:title => 'Success!'},"Your login, '#{self.name}', has been sucessfully created. You can now log in."]]
      end
      def menu(menu_name)
        menu_name='main' unless menu_name
        @menus[menu_name.to_sym].to_json
      end
    end
  end
end
