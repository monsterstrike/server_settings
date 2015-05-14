# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'server_settings/version'

Gem::Specification.new do |spec|
  spec.name          = "server_settings"
  spec.version       = ServerSettings::VERSION
  spec.authors       = ["Osamu MATSUMOTO"]
  spec.email         = ["osamu.matsumoto@gmail.com"]
  spec.summary       = %q{Server Configuration logic}
  spec.description   = %q{Server Configuration logic for any where}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec"
end
