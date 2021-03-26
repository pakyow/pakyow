# frozen_string_literal: true

require File.expand_path("../../../core/lib/pakyow/version", __FILE__)

Gem::Specification.new do |spec|
  spec.name = "pakyow-realtime"
  spec.version = Pakyow::VERSION
  spec.summary = "Pakyow Realtime"
  spec.description = "WebSockets and realtime channels for Pakyow"

  spec.author = "Bryan Powell"
  spec.email = "bryan@bryanp.org"
  spec.homepage = "https://pakyow.com"

  spec.required_ruby_version = ">= 2.7.2"

  spec.license = "LGPL-3.0"

  spec.files = Dir["CHANGELOG.md", "README.md", "LICENSE", "lib/**/*"]
  spec.require_path = "lib"

  spec.add_dependency "pakyow-core", Pakyow::VERSION
  spec.add_dependency "pakyow-presenter", Pakyow::VERSION
  spec.add_dependency "pakyow-routing", Pakyow::VERSION
  spec.add_dependency "pakyow-support", Pakyow::VERSION

  spec.add_dependency "core-async", "~> 0.5.0"

  spec.add_dependency "async-websocket", "~> 0.16.0"
  spec.add_dependency "concurrent-ruby", "~> 1.1"
  spec.add_dependency "redis", "~> 4.2"
end
