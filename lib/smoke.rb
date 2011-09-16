module Marley
  module Smoke
    DEFAULT_OPTS= {:method => 'get',:uri => '/',:params => {},:xhr => true,:expected_status => 200} 
    def smoke(*args)
      if args[0].class==Hash
        @opts=DEFAULT_OPTS.merge(args[0])
      else
        @opts=DEFAULT_OPTS
        @opts[:method]=args[0] if args[0]
        @opts[:uri]=args[1] if args[1]
        @opts[:params]=args[2] if args[2]
        @opts[:xhr]=args[3] if args[3]
        @opts[:expected_status]=args[4] if args[4]
      end
      @req=Rack::MockRequest.new(Marley::Router.new)
      resp=@req.request(@opts[:method],@opts[:uri],{:params => @opts[:params],'HTTP_X_REQUESTED_WITH' => @opts[:xhr] ? 'XMLHttpRequest' : ''})
      assert_equal @opts[:expected_status], resp.status
      json=JSON.parse(resp.body)
      yield json if block_given?
      json
    end
    [:get,:post,:put,:delete].each do |verb|
      define_method verb do |*args|
        smoke(verb,args)
      end
    end
  end
end
