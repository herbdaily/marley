
module Marley
  class Router  
    attr_reader :opts
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
      raise AuthenticationError if (@opts[:http_auth] && $request[:user].new? && ! Resources.constants.include?(rn))
      raise RoutingError unless Resources.const_defined?(rn)
      @resource=Resources.const_get(rn)
      raise AuthenticationError if @opts[:http_auth] && @resource.respond_to?('requires_user?') && @resource.requires_user? && $request[:user].new?
      @controller=nil #clear from previous call
      @controller=@resource.controller if @resource.respond_to?(:controller)
      @controller=@resource if @resource.respond_to?($request[:verb]) 
      raise RoutingError unless @controller
      json=@controller.send($request[:verb]).to_json
      html=@opts[:client] ? @opts[:client].to_s(json) : json
      resp_code=RESP_CODES[verb]
      headers||={'Content-Type' => "#{$request[:content_type]}; charset=utf-8"}
      [resp_code,headers,$request[:content_type].match(/json/) ? json : html]
    rescue Sequel::ValidationFailed
      ValidationError.new($!.errors).to_a
    rescue
      if $!.class.superclass==MarleyError
        $!.to_a
      else
        p $!,$!.class,$!.backtrace
      end
    ensure
      $log.info $request.merge({:request => nil,:user => $request[:user] ? $request[:user].name : nil})
      $request=nil #mostly for testing
    end
  end
end
