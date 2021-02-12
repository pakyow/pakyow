# frozen_string_literal: true

require File.expand_path("../../../core/lib/pakyow/version", __FILE__)

Gem::Specification.new do |spec|
  spec.name = "pakyow-assets"
  spec.version = Pakyow::VERSION
  spec.summary = "Pakyow Assets"
  spec.description = "Asset pipeline for Pakyow"

  spec.author = "Bryan Powell"
  spec.email = "bryan@bryanp.org"
  spec.homepage = "https://pakyow.com"

  spec.required_ruby_version = ">= 2.6.0"

  spec.license = "LGPL-3.0"

  spec.files = Dir["CHANGELOG.md", "README.md", "LICENSE", "lib/**/*", "src/**/*"]
  spec.require_path = "lib"

  spec.add_dependency "pakyow-core", Pakyow::VERSION
  spec.add_dependency "pakyow-presenter", Pakyow::VERSION
  spec.add_dependency "pakyow-routing", Pakyow::VERSION
  spec.add_dependency "pakyow-support", Pakyow::VERSION

  spec.add_dependency "async-http", "~> 0.54.1"
  spec.add_dependency "mini_mime", "~> 1.0"
  spec.add_dependency "mini_racer", "~> 0.3.1"
  spec.add_dependency "sassc", "~> 2.4"
  spec.add_dependency "source_map", "~> 3.0"
end
