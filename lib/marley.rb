#!/usr/bin/ruby
require 'rubygems'
require 'json/ext'
require 'thin'
require 'rack'
require 'rack/auth/basic'
require 'rack/builder'
require 'sequel_plugins'
require 'controllers'
require 'logger'
Sequel.extension :inflector

log_fn='log/marley.log'
$log=Logger.new(File.exists?(log_fn) ? log_fn : $stdout) 

module Marley
  JOINT_DIRS=["lib/joints/","#{File.dirname(__FILE__)}/joints/"]
  DEFAULT_OPTS={:defaults => {:resource => 'Menu'}}
  module Resources
  end
  module MainMethods #this module is included in the main object at the end of the file
    def marley_config(opts=nil)
      @marley_opts||={}
      @marley_opts.merge!(opts) if opts
      yield @marley_opts if block_given?
      @marley_opts
    end
    def joint(joint_name)
      joint_d=JOINT_DIRS.find {|d| File.exists?("#{d}#{joint_name}.rb") }
      require "#{joint_d}#{joint_name}"
      @marley_opts[:client] && @marley_opts[:client].joint(joint_d,joint_name)
    end
    def run(opts={})
      @marley_opts||={}
      marley_opts=@marley_opts.merge!(opts)
      Rack::Handler::Thin.run(Rack::Builder.new {
        use Rack::Reloader,0
        use Rack::Static, :urls => [opts[:image_path]] if opts[:image_path]
        run(Marley::Router.new(marley_opts))
      }.to_app,{:Port => 1620})
    end
  end
  class Router  
    def initialize(opts={},app=nil)
      @opts=DEFAULT_OPTS.merge(opts)
    end
    def call(env)
      request= Rack::Request.new(env)
      @auth =  Rack::Auth::Basic::Request.new(env)
      $request={:request => request}
      $request[:get_params]=Marley::Utils.hash_keys_to_syms(request.GET)
      $request[:post_params]=Marley::Utils.hash_keys_to_syms(request.POST)
      if (@auth.provided? && @auth.basic? && @auth.credentials)
        $request[:user]=Resources.const_get(:User).authenticate(@auth.credentials)
        raise AuthenticationError unless $request[:user]
      else
        $request[:user]=Resources.const_get(:User).new
      end
      $request[:path]=request.path.split('/')[1..-1]
      verb=request.request_method.downcase
      verb=$request[:post_params].delete(:_method).match(/^(put|delete)$/i)[1] rescue verb 
      $request[:verb]="rest_#{verb}"
      @resource=Resources.const_get($request[:path] ? $request[:path][0].camelize : @opts[:defaults][:resource])
      raise RoutingError $request[:path] unless @resource
      raise AuthenticationError if @resource.respond_to?('requires_user?') && @resource.requires_user? && $request[:user].new?
      @controller=@resource.respond_to?($request[:verb]) ? @resource : @resource.controller
      json=@controller.send($request[:verb]).to_json
      if request.xhr?
        [200,{'Content-Type' => 'application/json; charset=utf-8'}, json]
      elsif request.request_method.downcase=='post' #for iframe file upload hack
        [200,{'Content-Type' => 'text/html; charset=utf-8'}, json]
      else
        [200,{'Content-Type' => 'text/html; charset=utf-8'}, @opts[:client] ? @opts[:client].to_s(json) : json]
      end
    rescue AuthenticationError
      $log.error("Authentication failed for #{@auth.credentials}") if (@auth.provided? && @auth.basic? && @auth.credentials)
      [401,{'WWW-Authenticate' => %(Basic realm="Application")},'Not Authorized']
    rescue AuthorizationError
      $log.error($!.message)
      [403,{'Content-Type' => 'text/html'}, "<p>You are not authorized for this opteration: #{$!.message}</p>"]
    rescue RoutingError
      $log.fatal("#{$!.message}\n#{$!.backtrace}")
      [500,{'Content-Type' => 'text/html'}, "<p>A routing error has occurred: #{$!.message}</p><pre>#{$!.backtrace.join("\n")}</pre><pre>#{$request[:request].inspect}</pre>"]
    rescue Sequel::ValidationFailed
      $log.error($!.errors)
      [500,{'Content-Type' => 'application/json'}, [:validation,$!.errors].to_json]
    rescue
      $log.fatal("#{$!.message}\n#{$!.backtrace}")
      [500,{'Content-Type' => 'text/html'}, "<p>#{$!.message}</p><pre>#{$!.backtrace.join("\n")}</pre><pre>#{$request[:request].inspect}</pre><pre>#{$!.inspect}</pre>"]
    ensure
      $log.info $request.merge({:request => nil,:user => $request[:user] ? $request[:user].name : nil})
    end
  end
  class AuthenticationError < StandardError; end
  class AuthorizationError < StandardError; end
  class RoutingError < StandardError
    def initialize(resource,instance=nil,method=nil)
      if method
        if instance
          @message="Instances of model #{resource} do not respond to method #{method}"
        else
          @message="Model #{resource} does not respond to method #{method}"
        end
      else
        @message="No resource named #{resource} exists"
      end
    end
    def to_s
      @message
    end
  end
  module Utils
    def self.hash_keys_to_syms(hsh)
      hsh.inject({}) {|h,(k,v)| h[k.to_sym]= v.class==Hash ? hash_keys_to_syms(v) : v;h }
    end
  end
end
include Marley::MainMethods
