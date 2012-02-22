# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{marley}
  s.version = "0.6.0"
  s.summary = %q{Irie default restful routes for models and other objects}
  s.description = %q{Marley is a framework for quickly building RESTful web services and applications.  Development is fast because Marley implements lots of sensible defaults, all of which can be overridden and most of which can be overridden easily. }
  s.authors     = ["Herb Daily"]
  s.email       = 'herb.daily@safe-mail.net'
  s.homepage    = 'http://github.com/herbdaily/marley'
  s.required_rubygems_version = Gem::Requirement.new(">= 1.0.0") if s.respond_to? :required_rubygems_version=
  s.add_runtime_dependency 'sequel', '~>3.27'
  s.add_runtime_dependency 'rack', '~>1.2.2'
  s.add_runtime_dependency 'json', '~>1.1.7'
  s.add_development_dependency 'tdoc', '~>0.13.4'
  s.files = Dir.glob(["README.rdoc","reggae.ebnf","lib/**/*","rdoc/**/*"])
end
