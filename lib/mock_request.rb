module Marley
  class MockRequest < Rack::MockRequest
    include Test::Unit::Assertions
    DEFAULT_OPTS={:method => 'get',:uri => '/',:params => {},:xhr => true,:expected_status => 200} 
    attr_accessor :opts
    def initialize(*args)
      if args[0].class==Hash
        @opts=DEFAULT_OPTS.merge(args[0])
      else
        @opts=DEFAULT_OPTS
        foo=nil
        @opts[:app]=foo if (foo=args.shift)
        @opts[:method]=foo if (foo=args.shift)
        @opts[:uri]=foo if (foo=args.shift)
        @opts[:params]=foo if (foo=args.shift)
        @opts[:xhr]=foo if (foo=args.shift)
        @opts[:expected_status]=foo if (foo=args.shift)
      end
      @app=@opts[:app] || Marley::Router.new
    end
    def request(*args)
      if args[0].class==Hash
        opts=(@opts||DEFAULT_OPTS).merge(args[0])
      else
        foo=nil
        opts=@opts||DEFAULT_OPTS
        opts[:method]=foo if (foo=args.shift)
        opts[:uri]=foo if (foo=args.shift)
        opts[:params]=foo if (foo=args.shift)
        opts[:xhr]=foo if (foo=args.shift)
        opts[:expected_status]=foo if (foo=args.shift)
      end
      res=super opts[:method],opts[:uri],{:params => opts[:params],'HTTP_X_REQUESTED_WITH' => opts[:xhr] ? 'XMLHttpRequest' : ''}
      assert_equal opts[:expected_status],res.status
      res.headers['Content-Type'].match(/^application\/json/) ? JSON.parse(res.body) : res.body
    end
    [:get,:post,:put,:delete].each do |verb|
      define_method verb do |*args|
        request({:method => verb.to_s}.merge(args[0] || {}))
      end
    end

  end
end
