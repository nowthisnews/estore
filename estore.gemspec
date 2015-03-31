# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'estore/version'

Gem::Specification.new do |spec|
  spec.name          = 'estore'
  spec.version       = Estore::VERSION
  spec.authors       = ['Mathieu Ravaux', 'Héctor Ramón']
  spec.email         = ['mathieu.ravaux@gmail.com', 'hector0193@gmail.com']
  spec.summary       = 'An Event Store driver for Ruby'
  spec.description   = spec.summary
  spec.homepage      = 'https://github.com/rom-eventstore/estore'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(/^bin\//) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(/^spec\//)
  spec.require_paths = ['lib']

  spec.add_dependency 'beefcake', '~> 1.1.0.pre1'
  spec.add_dependency 'promise.rb', '~> 0.6.1'

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rubocop', '~> 0.28.0'
end
