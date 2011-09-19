#shamelessly stolen from https://github.com/josephruscio/rack-test-rest and refactored with some functionality changes
module Marley
  module TestHelpers
      CRUD2REST={'create' => 'post','read' => 'get','update' => 'put', 'delete' => 'delete'}
      def resource_uri
        "#{@marley_test[:root_uri]}/#{@marley_test[:resource]}"
      end
      def process(method,params={})
        expected_code = params.delete(:code)
        puts "#{method} to: '#{resource_uri}#{@marley_test[:extension]}'" if @marley_test[:debug]
        puts "params: #{params}" if @marley_test[:debug]
        send(method,resource_uri,params)
        assert_equal(expected_code || RESP_CODES[method],last_response.status)
        JSON.parse(last_response.body) rescue last_response.body
      end
      ['create','read','update','delete'].each do |op|
        define_method("marley_#{op}".to_sym) do |params| 
          process(CRUD2REST[op],params)
        end
      end
  end
end
