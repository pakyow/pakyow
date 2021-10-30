# frozen_string_literal: true

require File.expand_path("../core/lib/pakyow/version", __FILE__)

Gem::Specification.new do |spec|
  spec.name = "pakyow"
  spec.version = Pakyow::VERSION
  spec.summary = "Pakyow"
  spec.description = "Design-First Web Framework"

  spec.author = "Bryan Powell"
  spec.email = "bryan@bryanp.org"
  spec.homepage = "https://pakyow.com"

  spec.required_ruby_version = ">= 3.0.2"

  spec.license = "LGPL-3.0"

  spec.files = Dir["CHANGELOG.md", "README.md", "LICENSE", "lib/**/*"]
  spec.require_path = "lib"

  spec.add_dependency "pakyow-assets", Pakyow::VERSION
  spec.add_dependency "pakyow-core", Pakyow::VERSION
  spec.add_dependency "pakyow-data", Pakyow::VERSION
  spec.add_dependency "pakyow-form", Pakyow::VERSION
  spec.add_dependency "pakyow-mailer", Pakyow::VERSION
  spec.add_dependency "pakyow-presenter", Pakyow::VERSION
  spec.add_dependency "pakyow-realtime", Pakyow::VERSION
  spec.add_dependency "pakyow-reflection", Pakyow::VERSION
  spec.add_dependency "pakyow-routing", Pakyow::VERSION
  spec.add_dependency "pakyow-support", Pakyow::VERSION
  spec.add_dependency "pakyow-ui", Pakyow::VERSION
end
