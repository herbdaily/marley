require "rack/test"
require 'reggae'
#shamelessly stolen from https://github.com/josephruscio/rack-test-rest and refactored with some functionality changes
module Marley
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
