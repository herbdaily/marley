#shamelessly stolen from https://github.com/josephruscio/rack-test-rest and refactored with some functionality changes
module Marley
  module TestHelpers
      CRUD2REST={'create' => 'post','read' => 'get','update' => 'put', 'delete' => 'delete'}
      def resource_uri
        "#{@marley_test[:root_uri]}/#{@marley_test[:resource]}"
      end
      def process(method,params={})
        expected_code = params.delete(:code) if params
        puts "#{method} to: '#{resource_uri}#{@marley_test[:extension]}'" if @marley_test[:debug]
        puts "params: #{params}" if @marley_test[:debug]
        send(method,resource_uri,params)
        assert_equal(expected_code || RESP_CODES[method],last_response.status)
        Reggae.new(JSON.parse(last_response.body)) rescue last_response.body
      end
      ['create','read','update','delete'].each do |op|
        define_method("marley_#{op}".to_sym) do |params| 
          process(CRUD2REST[op],params)
        end
      end
  end
  class Reggae < Array
    def resource
      self[0].class==String ? self[0] : nil
    end
    def properties
      self[1].class==Hash ? self[1] : nil
    end
    def contents
      resource ? self[2] : nil
    end
    def is_resource?
      ! resource.nil?
    end
    def [](n)
      if super(n).class==Array
        self.class.new(super(n))
      else
        super(n)
      end
    end
    def name
      self.properties && self.properties['name'] || self.properties['uri']
    end
    def schema
      self.resource.to_s=='instance' && ReggaeSchema.new(self.properties.schema)
    end
    def find_resource(rn)
      if is_resource?
        self.name.to_s==rn ? self : (contents.nil? ? nil : contents.find_resource(rn))
      else
        find {|a| self.class.new(a).find_resource(rn)}
      end
    end
    class ReggaeSchema < Array
    end
  end
end
