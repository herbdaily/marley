require "rack/test"
require 'marley/reggae'
module Marley
  class TestClient
    CRUD2REST={'create' => 'post','read' => 'get','update' => 'put', 'del' => 'delete'}
    DEFAULT_OPTS={:url => nil,:root_url => nil, :resource_name => nil, :instance_id => nil, :method => nil, :extention =>nil, :auth => nil, :code => nil, :debug => nil}
    include Rack::Test::Methods
    attr_reader :opts
    def app
      Marley::Router.new
    end
    def initialize(opts={})
      @opts=DEFAULT_OPTS.merge(opts)
    end
    def make_url(opts=nil)
      opts||=@opts
      opts[:url] || '/' + [:root_url, :resource_name, :instance_id, :method].map {|k| opts[k]}.compact.join('/') + opts[:extention].to_s
    end
    def process(verb,params={},opts={})
      #p 'params:',params,'opts:',opts,"-------------" if opts
      opts||={}
      opts=@opts.merge(opts)
      expected_code=opts[:code] || RESP_CODES[verb]
      params=params.to_params if params.respond_to?(:to_params)
      if opts[:debug]
        p opts
        p "#{verb} to: '#{make_url(opts)}'" 
        p params 
        p opts[:auth]
      end
      authorize opts[:auth][0],opts[:auth][1] if opts[:auth]
      header 'Authorization',nil unless opts[:auth]  #clear auth from previous requests
      send(verb,make_url(opts),params)
      #p last_response.body if opts[:debug]
      #p JSON.parse(last_response.body) if opts[:debug]
      p last_response.status if opts[:debug]
      p expected_code if opts[:debug]
      return false unless (expected_code || RESP_CODES[method])==last_response.status
      Reggae.get_resource(JSON.parse(last_response.body)) rescue last_response.body
    end
    ['create','read','update','del'].each do |op|
      define_method op.to_sym, Proc.new { |*args| 
        process(CRUD2REST[op],args[0],args[1])
      }
    end
    DEFAULT_OPTS.keys.each do |opt|
      define_method opt, Proc.new { 
        @opts[opt]
      }
      define_method "#{opt}=", Proc.new { |val| 
        @opts[opt]=val
      }
    end
  end
end
