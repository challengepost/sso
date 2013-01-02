# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "sso/version"

Gem::Specification.new do |s|
  s.name        = "sso"
  s.version     = SSO::VERSION
  s.authors     = ["John Allison"]
  s.email       = ["jrallison@gmail.com"]
  s.homepage    = "http://github.com/challengepost/sso"
  s.summary     = "Rack middleware for cross-domain single sign on"
  s.description = ""

  s.files         = Dir["lib/**/*"] + ["Rakefile", "README.markdown"]
  s.test_files    = Dir["spec/**/*"]
  s.require_paths = ["lib"]

  s.add_runtime_dependency('activesupport')
  s.add_runtime_dependency('actionpack', ["~> 3.1.3"])
  s.add_runtime_dependency('redis')

  s.add_development_dependency('rspec')
  s.add_development_dependency('rack-test')
  s.add_development_dependency('debugger')
  s.add_development_dependency('mock_redis')
end
