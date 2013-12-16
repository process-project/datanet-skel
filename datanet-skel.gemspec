# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'datanet-skel/version'

Gem::Specification.new do |gem|
  gem.name          = "datanet-skel"
  gem.version       = Datanet::Skel::VERSION
  gem.authors       = ["Marek Kasztelnik"]
  gem.email         = ["mkasztelnik@gmail.com"]
  gem.summary       = %q{REST interface for datanet models.}
  gem.description   = %q{Skeleton for datanet models.}
  gem.homepage      = "https://github.com/dice-cyfronet/datanet-skel"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib", "api"]

  gem.add_runtime_dependency 'grape', '0.6.0'
  gem.add_runtime_dependency 'sinatra'
  gem.add_runtime_dependency 'json'
  gem.add_runtime_dependency 'json-schema'
  gem.add_runtime_dependency 'settingslogic'
  gem.add_runtime_dependency 'rack-stream'

  #gem.add_development_dependency
end
