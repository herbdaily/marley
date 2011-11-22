#!/usr/bin/ruby
require 'json/ext'
require 'json/add/core'
require 'marley/reggae'
require 'marley/utils'
require 'marley/orm'
require 'rack'
require 'rack/auth/basic'
require 'rack/builder'
require 'sequel/plugins/rest_convenience'
require 'sequel/plugins/rest_auth'
require 'marley/controllers'
require 'logger'
Sequel.extension :inflector

Sequel::Model.plugin :rest_convenience
Sequel::Model.plugin :rest_authorization
Sequel::Model.plugin :validation_helpers
Sequel::Plugins::ValidationHelpers::DEFAULT_OPTIONS.merge!(:presence => {:message => 'is required'})
Sequel::Model.plugin :timestamps, :create => :date_created, :update => :date_updated

log_fn='log/marley.log'
$log=Logger.new(File.exists?(log_fn) ? log_fn : $stdout) 

# This is the main Marley namespace
module Marley 
  JOINT_DIRS=[File.expand_path("joints/",File.dirname(__FILE__)),"#{Dir.pwd}/joints"]
  # @see config
  DEFAULT_OPTS={:http_auth => true,:app_name => 'Application',:port => 1620,:default_user_class => :User, :auth_class => :User,:default_resource => 'Menu', :server => 'thin'}
  RESP_CODES={'get' => 200,'post' => 201,'put' => 204,'delete' => 204}
  
  # All constants in the Resources namespace should refer to public resources accessible to clients, subject, of course, to authentication/authorization.
  #
  # Resources MUST respond to one or more of #controller, #rest_get, #rest_post, #rest_put, #rest_delete
  #
  # If a Resource implements a #controller method, the method MUST return an object which responds to one or more of #rest_get, #rest_post, #rest_put, #rest_delete
  module Resources 
  end
  # The default namespace for Joints. Joints MUST implement a #smoke method
  module Joints
  end
  require 'marley/joint' #this needs to happen after Marley::Resources is defined
  
  # Override default Marley configuration
  # @param [Hash] opts A hash containing Marley configuration options
  # @option opts [Boolean] :http_auth Whether or not to use http authentication
  # @option opts [String] :app_name Currently used by Jamaica to set page title
  # @option opts [Number] :port Port on which to run the server
  # @option opts [Object] :default_user_class The default class of the new user assigned to $request[:user] if no actual user is authenticated
  # @option opts [Object] :auth_class The class used to authenticate requests.  MUST respond to #authenticate
  # @option opts [Object] :default_resource The resource called in response to a request to '/'
  # @option opts [String] :server  the Rack web server to be used.
  def self.config(opts=nil)
    @marley_opts||=DEFAULT_OPTS
    @marley_opts.merge!(opts) if opts
    yield @marley_opts if block_given?
    @marley_opts
  end
  
  # Loads a joint and and calls its #smoke method
  # @param [String] joint_name The name of the joint to load and smoke - additional paramters passed through to the joint itself
  def self.joint(joint_name, *opts)
    joint_d=JOINT_DIRS.find {|d| File.exists?("#{d}/#{joint_name}.rb") }
    require "#{joint_d}/#{joint_name}"
    @marley_opts && @marley_opts[:client] && @marley_opts[:client].joint(joint_d,joint_name)
    joint=Marley::Joints.const_get(joint_name.camelize).new(*opts).smoke
  end

  # Runs the server
  # @param (see #config)
  def self.run(opts={})
    @marley_opts||=DEFAULT_OPTS
    marley_opts=@marley_opts.merge!(opts)
    Rack::Handler.get(marley_opts[:server]).run(Rack::Builder.new {
      use Rack::Reloader,0
      use Rack::Static, :urls => [opts[:image_path]] if opts[:image_path]
      run(Marley::Router.new(marley_opts))
    }.to_app,{:Port => @marley_opts[:port]})
  end
  class Router  #the default Marley router.  Creates the $request object, locates the resource requested and calls either its controller's or its own rest verb method
    def initialize(opts={},app=nil)
      @opts=DEFAULT_OPTS.merge(opts)
    end
    def call(env)
      request= Rack::Request.new(env)
      @auth =  Rack::Auth::Basic::Request.new(env)
      $request={:request => request,:opts => @opts}
      $request[:get_params]=Marley::Utils.hash_keys_to_syms(request.GET)
      $request[:post_params]=Marley::Utils.hash_keys_to_syms(request.POST)
      $request[:content_type]=request.xhr? ? 'application/json' : env['HTTP_ACCEPT'].to_s.sub(/,.*/,'') 
      $request[:content_type]='text/html' unless $request[:content_type] > ''
      $request[:content_type]='application/json' if env['rack.test']==true #there has to be a better way to do this...
      if @opts[:http_auth]
        if (@auth.provided? && @auth.basic? && @auth.credentials)
          $request[:user]=Resources.const_get(@opts[:auth_class]).authenticate(@auth.credentials)
          raise AuthenticationError unless $request[:user]
        else
          $request[:user]=Resources.const_get(@opts[:default_user_class]).new
        end
      end
      $request[:path]=request.path.sub(/\/\/+/,'/').split('/')[1..-1]
      verb=request.request_method.downcase
      verb=$request[:post_params].delete(:_method).match(/^(put|delete)$/i)[1] rescue verb 
      $request[:verb]="rest_#{verb}"
      rn=$request[:path] ? $request[:path][0].camelize : @opts[:default_resource]
      raise RoutingError unless Resources.constants.include?(rn)
      @resource=Resources.const_get(rn)
      raise AuthenticationError if @opts[:http_auth] && @resource.respond_to?('requires_user?') && @resource.requires_user? && $request[:user].new?
      @controller=@resource.respond_to?($request[:verb]) ? @resource : @resource.controller
      json=@controller.send($request[:verb]).to_json
      html=@opts[:client] ? @opts[:client].to_s(json) : json
      resp_code=RESP_CODES[verb]
      headers||={'Content-Type' => "#{$request[:content_type]}; charset=utf-8"}
      [resp_code,headers,$request[:content_type].match(/json/) ? json : html]
    rescue Sequel::ValidationFailed
      ValidationError.new($!.errors).to_a
    rescue
      ($!.class.new.respond_to?(:to_a) ?  $!.class : MarleyError).new.to_a
    ensure
      $log.info $request.merge({:request => nil,:user => $request[:user] ? $request[:user].name : nil})
    end
  end
  class MarleyError < StandardError
    class << self
      attr_accessor :resp_code,:headers,:description,:details
    end
    @resp_code=500
    def initialize
      self.class.details=self.backtrace
    end
    def log_error
      $log.fatal("#$!.message}\n#{$!.backtrace}")
    end
    def to_a
      log_error
      json=[:error,{:error_type => self.class.name.underscore.sub(/_error$/,'').sub(/^marley\//,''),:description => self.class.description, :error_details => self.class.details}].to_json
      self.class.headers||={'Content-Type' => "#{$request[:content_type]}; charset=utf-8"}
      [self.class.resp_code,self.class.headers,json]
    end
  end
  class ValidationError < MarleyError
    @resp_code=400
    def initialize(errors)
      self.class.details=errors
    end
    def log_error
      $log.error(self.class.details)
    end
  end
  class AuthenticationError < MarleyError
    @resp_code=401
    @headers={'WWW-Authenticate' => %(Basic realm="Application")}
    def log_error
      $log.error("Authentication failed for #{@auth.credentials[0]}") if (@auth && @auth.provided? && @auth.basic? && @auth.credentials)
    end
  end
  class AuthorizationError < MarleyError
    @resp_code=403
    @description='You are not authorized for this operation'
    def log_error
      $log.error("Authorizationt Error:#{self.message}")
    end
  end
  class RoutingError < MarleyError
    @resp_code=404
    @description='Not Found'
    def log_error
      $log.fatal("path:#{$request[:path]}\n   msg:#{$!.message}\n   backtrace:#{$!.backtrace}")
    end
  end
end
  MR=Marley::Resources
  MJ=Marley::Joints
at_exit {Marley.run  if ARGV[0]=='run'}
