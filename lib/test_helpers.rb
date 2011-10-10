require "rack/test"
require 'reggae'
#shamelessly stolen from https://github.com/josephruscio/rack-test-rest and refactored with some functionality changes
module Marley
  class TestClient
    CRUD2REST={'create' => 'post','read' => 'get','update' => 'put', 'delete' => 'delete'}
    DEFAULT_OPTS={:root_url => nil, :resource_name => nil, :instance_id => nil, :method => nil, :extention =>nil, :auth => nil, :code => nil, :debug => nil}
    include Rack::Test::Methods
    attr_reader :opts
    def app
      Marley::Router.new
    end
    def initialize(opts)
      @opts=DEFAULT_OPTS.merge(opts)
    end
    def url(opts=nil)
      opts||=@opts
      '/' + [:root_url, :resource_name, :instance_id, :method].map {|k| opts[k]}.compact.join('/') + opts[:extention].to_s
    end
    def process(verb,params={},opts={})
      opts||={}
      opts=@opts.merge(opts)
      expected_code=opts[:code] || RESP_CODES[verb]
      if opts[:debug]
        p opts
        p "#{verb} to: '#{url(opts)}'" 
        p params 
        p opts[:auth]
      end
      authorize opts[:auth][0],opts[:auth][1] if opts[:auth]
      send(verb,url(opts),params)
      p last_response.status if opts[:debug]
      return false unless (expected_code || RESP_CODES[method])==last_response.status
      Reggae.new(JSON.parse(last_response.body)) rescue last_response.body
    end
    ['create','read','update','delete'].each do |op|
      define_method op.to_sym, Proc.new { |params,opts| 
        process(CRUD2REST[op],params,opts)
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
  module TestHelpers
    CRUD2REST={'create' => 'post','read' => 'get','update' => 'put', 'delete' => 'delete'}
    include Rack::Test::Methods
    def resource_uri
      @marley_test[:resource].sub!(/^\/+/,'')
      "#{@marley_test[:root_uri]}/#{@marley_test[:resource]}"
    end
    def process(method,params={},opts={})
      expected_code = params.delete(:code) if params
      p "#{method} to: '#{resource_uri}#{@marley_test[:extension]}'" if @marley_test[:debug]
      p params if @marley_test[:debug]
      send(method,resource_uri,params)
      return false unless (expected_code || RESP_CODES[method])==last_response.status
      #assert_equal(expected_code || RESP_CODES[method],last_response.status)
      Reggae.new(JSON.parse(last_response.body)) rescue last_response.body
    end
    ['create','read','update','delete'].each do |op|
      define_method("marley_#{op}".to_sym) do |params| 
        process(CRUD2REST[op],params)
      end
    end
  end
end
