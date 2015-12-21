# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'bitcoin_ticker/version'

Gem::Specification.new do |spec|
  spec.name          = "bitcoin_ticker"
  spec.version       = BitcoinTicker::VERSION
  spec.authors       = ["robbiewain"]
  spec.summary       = "A bitcoin ticker for Slack"
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = ["bitcoin-ticker"]
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"

  spec.add_dependency "redis", "~>3.2"
end
