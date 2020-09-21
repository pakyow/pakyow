# frozen_string_literal: true

require File.expand_path("../../pakyow-core/lib/pakyow/version", __FILE__)

Gem::Specification.new do |spec|
  spec.name = "pakyow-data"
  spec.version = Pakyow::VERSION
  spec.summary = "Pakyow Data"
  spec.description = "Data persistence layer for Pakyow"

  spec.author = "Bryan Powell"
  spec.email = "bryan@bryanp.org"
  spec.homepage = "https://pakyow.com"

  spec.required_ruby_version = ">= 2.5.0"

  spec.license = "LGPL-3.0"

  spec.files = Dir["CHANGELOG.md", "README.md", "LICENSE", "lib/**/*"]
  spec.require_path = "lib"

  spec.add_dependency "pakyow-core", Pakyow::VERSION
  spec.add_dependency "pakyow-support", Pakyow::VERSION

  spec.add_dependency "concurrent-ruby", "~> 1.1"
  spec.add_dependency "connection_pool", "~> 2.2"
  spec.add_dependency "dry-types", "~> 1.4"
  spec.add_dependency "redis", "~> 4.1"
  spec.add_dependency "sequel", "~> 5.32"
end
