# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'perm/version'

Gem::Specification.new do |spec|
  spec.name          = "perm"
  spec.version       = Perm::VERSION
  spec.authors       = ["Chris Hoffman", "John Nestoriak"]
  spec.email         = ["yarmiganosca@gmail.com"]
  spec.summary       = "Write migrations for your permissions."
  spec.description   = "Write migrations for your permissions."
  spec.homepage      = "https://github.com/yarmiganosca/perm"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.5"
  spec.add_development_dependency "rake"
end
