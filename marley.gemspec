# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{marley}
  s.version = "0.5.0"
  s.summary = %q{Irie default restful routes for your models and other objects}
  s.description = %q{Marley implements a web services framework on top of Rack and Sequel on the server side and Jquery on the client side.  }
  s.authors     = ["Herb Daily"]
  s.email       = 'herb.daily@safe-mail.net'
  s.homepage    = 'http://github.com/herbdaily/marley'
  s.required_rubygems_version = Gem::Requirement.new(">= 1.0.0") if s.respond_to? :required_rubygems_version=
  s.add_runtime_dependency 'sequel', '~>3.27'
  s.add_runtime_dependency 'rack', '~>1.2.2'
  s.add_runtime_dependency 'json', '~>1.1.7'
  s.add_development_dependency 'tdoc', '~>0.12.1'
  s.files = Dir.glob(["*","lib/**/*","examples/**/*","test/**/*"])
end
