module Marley
  class MarleyError < StandardError
    class << self
      attr_accessor :resp_code,:headers,:description,:details
    end
    @resp_code=500
    def initialize
      self.class.details=self.backtrace
    end
    def log_error
      $log.fatal("#$!.message}\n#{$!.backtrace}")
    end
    def to_a
      log_error
      json=[:error,{:error_type => self.class.name.underscore.sub(/_error$/,'').sub(/^marley\//,''),:description => self.class.description, :error_details => self.class.details}].to_json
      self.class.headers||={'Content-Type' => "#{$request[:content_type]}; charset=utf-8"}
      [self.class.resp_code,self.class.headers,json]
    end
  end
  class ValidationError < MarleyError
    @resp_code=400
    def initialize(errors)
      self.class.details=errors
    end
    def log_error
      $log.error(self.class.details)
    end
  end
  class AuthenticationError < MarleyError
    @resp_code=401
    @headers={'WWW-Authenticate' => %(Basic realm="Application")}
    def log_error
      $log.error("Authentication failed for #{@auth.credentials[0]}") if (@auth && @auth.provided? && @auth.basic? && @auth.credentials)
    end
  end
  class AuthorizationError < MarleyError
    @resp_code=403
    @description='You are not authorized for this operation'
    def log_error
      $log.error("Authorizationt Error:#{self.message}")
    end
  end
  class RoutingError < MarleyError
    @resp_code=404
    @description='Not Found'
    def log_error
      $log.fatal("path:#{$request[:path]}\n   msg:#{$!.message}\n   backtrace:#{$!.backtrace}")
    end
  end
end

