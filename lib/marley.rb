#!/usr/bin/env ruby
require 'json/ext'
require 'json/add/core'
require 'rack'
require 'rack/auth/basic'
require 'rack/builder'
require 'logger'
require 'sequel'
require 'marley/core_ext'
require 'marley/utils'
require 'marley/reggae'
require 'marley/errors'
require 'marley/router'
require 'marley/resources'
require 'marley/controllers'
require 'marley/joint' 
require 'marley/plugin' 
Sequel.extension :inflector

Sequel::Model.plugin :validation_helpers
Sequel::Plugins::ValidationHelpers::DEFAULT_OPTIONS.merge!(:presence => {:message => 'is required'})
Sequel::Model.plugin :timestamps, :create => :date_created, :update => :date_updated

log_fn='log/marley.log'
$log=Logger.new(File.exists?(log_fn) ? log_fn : $stdout) 

module Marley 
  DEFAULT_OPTS={:http_auth => true,:app_name => 'Application',:port => 1620,:default_user_class => :User, :auth_class => :User,:default_resource => 'Menu', :server => 'thin'}
  RESP_CODES={'get' => 200,'post' => 201,'put' => 204,'delete' => 204}
  
  def self.config(opts=nil)
    @marley_opts||=DEFAULT_OPTS
    @marley_opts.merge!(opts) if opts
    yield @marley_opts if block_given?
    @marley_opts
  end
  
  def self.plugin(plugin_name, *opts)
    Plugins.const_get(plugin_name.to_s.camelize).new(*opts)
  end
  def self.joint(joint_name, *opts)
    Joints.const_get(joint_name.to_s.camelize).new(*opts).smoke
  end

  def self.run(opts={})
    marley_opts=self.configure(opts)
    Rack::Handler.get(marley_opts[:server]).run(Rack::Builder.new {
      use Rack::Reloader,0
      use Rack::Static, :urls => [opts[:image_path]] if opts[:image_path]
      run(Marley::Router.new(marley_opts))
    }.to_app,{:Port => @marley_opts[:port]})
  end
end
MR=Marley::Resources
MJ=Marley::Joints
MP=Marley::Plugins
MU=Marley::Utils
at_exit {Marley.run  if ARGV[0]=='run'}
