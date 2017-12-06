# frozen_string_literal: true

require File.expand_path("../../lib/pakyow/version", __FILE__)

Gem::Specification.new do |spec|
  spec.name        = "pakyow-realtime"
  spec.version     = Pakyow::VERSION
  spec.summary     = "Pakyow Realtime"
  spec.description = "WebSockets and realtime channels for Pakyow"

  spec.author   = "Bryan Powell"
  spec.email    = "bryan@metabahn.com"
  spec.homepage = "https://pakyow.org"

  spec.required_ruby_version = ">= 2.4.0"

  spec.license = "MIT"

  spec.files        = Dir["CHANGELOG.md", "README.md", "LICENSE", "lib/**/*"]
  spec.require_path = "lib"

  spec.add_dependency "pakyow-core", Pakyow::VERSION
  spec.add_dependency "pakyow-support", Pakyow::VERSION

  spec.add_dependency "concurrent-ruby", "~> 1.0"
  spec.add_dependency "websocket-driver", "~> 0.7"
  spec.add_dependency "nio4r", "~> 2.1"
  spec.add_dependency "redis", "~> 4.0"
end
