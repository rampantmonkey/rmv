# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'menagerie_generator/version'

Gem::Specification.new do |spec|
  spec.name          = "menagerie-generator"
  spec.version       = MenagerieGenerator::VERSION
  spec.authors       = ["Casey Robinson"]
  spec.email         = ["kc@rampantmonkey.com"]
  spec.description   = %q{Parse and analyze logs from resource monitor}
  spec.summary       = %q{Longer version of description}
  spec.homepage      = "http://www3.nd.edu/~ccl/workflows/"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3.0"
  spec.add_development_dependency "rake"
end
