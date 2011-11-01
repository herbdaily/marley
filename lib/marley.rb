#!/usr/bin/ruby
$: << File.dirname(__FILE__)
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


module Marley #The main Marley namespace.
  JOINT_DIRS=[File.expand_path("joints/",File.dirname(__FILE__)),"#{Dir.pwd}/joints"]
  DEFAULT_OPTS={:http_auth => true,:app_name => 'Application',:port => 1620,:default_user_class => :User, :auth_class => :User,:default_resource => 'MainMenu', :server => 'thin'}
  RESP_CODES={'get' => 200,'post' => 201,'put' => 204,'delete' => 204}
  
  module Resources #All objects in the Resources namespace are exposed by the server.
  end
  def self.config(opts=nil)
    @marley_opts||=DEFAULT_OPTS
    @marley_opts.merge!(opts) if opts
    yield @marley_opts if block_given?
    @marley_opts
  end
  def self.joint(joint_name)
    joint_d=JOINT_DIRS.find {|d| File.exists?("#{d}/#{joint_name}.rb") }
    require "#{joint_d}/#{joint_name}"
    @marley_opts[:client] && @marley_opts[:client].joint(joint_d,joint_name)
  end
  def self.run(opts={})
    @marley_opts||=DEFAULT_OPTS
    marley_opts=@marley_opts.merge!(opts)
    Rack::Handler.get(marley_ops[:server]).run(Rack::Builder.new {
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
    rescue AuthenticationError
      $log.error("Authentication failed for #{@auth.credentials}") if (@auth.provided? && @auth.basic? && @auth.credentials)
      resp_code=401
      headers={'WWW-Authenticate' => %(Basic realm="Application")}
      json=html='You must log in'
    rescue AuthorizationError
      $log.error($!.message)
      resp_code=403
      json=[:authorization,{:message => 'Not authorized'}].to_json
      html="<p>You are not authorized for this opteration: #{$!.message}</p>"
    rescue RoutingError
      $log.fatal("#{$!.message}\n#{$!.backtrace}")
      resp_code=404
      json=[:routing,{:message => $!.message}].to_json
      html="<p>A routing error has occurred: #{$!.message}</p><pre>#{$!.backtrace.join("\n")}</pre><pre>#{$request[:request].inspect}</pre>"
    rescue Sequel::ValidationFailed
      $log.error($!.errors)
      resp_code=400
      json=[:validation,$!.errors].to_json
      html="<pre>#{$!.errors}</pre>"
    rescue
      p $!.message
      p $!.backtrace
      $log.fatal("#{$!.message}\n#{$!.backtrace}")
      resp_code=500
      json=[:unknown, {:message => $!.message,:backtrace => $!.backtrace}].to_json
      html="<p>#{$!.message}</p><pre>#{$!.backtrace.join("\n")}</pre><pre>#{$request[:request].inspect}</pre><pre>#{$!.inspect}</pre>"
    ensure
      $log.info $request.merge({:request => nil,:user => $request[:user] ? $request[:user].name : nil})
      content_type=request.xhr? ? 'application/json' : env['HTTP_ACCEPT'].to_s.sub(/,.*/,'') 
      content_type='text/html' unless content_type > ''
      content_type='application/json' if env['rack.test']==true #there has to be a better way to do this...
      headers||={'Content-Type' => "#{content_type}; charset=utf-8"}
      return [resp_code,headers,content_type.match(/json/) ? json : html]
    end
  end
  class AuthenticationError < StandardError; end
  class AuthorizationError < StandardError; end
  class RoutingError < StandardError; end
  module Utils
    def self.hash_keys_to_syms(hsh)
      hsh.inject({}) {|h,(k,v)| h[k.to_sym]= v.class==Hash ? hash_keys_to_syms(v) : v;h }
    end
  end
end
#include Marley::MainMethods
at_exit {run  if ARGV[0]=='run'}
