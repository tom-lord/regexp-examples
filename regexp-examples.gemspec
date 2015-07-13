require File.expand_path('../lib/regexp-examples/version', __FILE__)

Gem::Specification.new do |s|
  s.name             = 'regexp-examples'
  s.version          = RegexpExamples::VERSION
  s.summary          = "Extends the Regexp class with '#examples'"
  s.description      =
    'Regexp#examples returns a list of strings that are matched by the regex'
  s.authors          = ['Tom Lord']
  s.email            = 'lord.thom@gmail.com'
  s.files            = `git ls-files -z`.split("\x0")
  s.executables      = s.files.grep(%r{^bin/}) { |f| File.basename(f) }
  s.test_files       = s.files.grep(%r{^(test|spec|features)/})
  s.require_paths    = ['lib']
  s.homepage         =
    'http://rubygems.org/gems/regexp-examples'
  s.add_development_dependency 'bundler', '~> 1.7'
  s.add_development_dependency 'rake', '~> 10.0'
  s.license          = 'MIT'
  s.required_ruby_version = '>= 2.0.0'
end
