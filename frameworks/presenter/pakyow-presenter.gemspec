# frozen_string_literal: true

require File.expand_path("../../../core/lib/pakyow/version", __FILE__)

Gem::Specification.new do |spec|
  spec.name = "pakyow-presenter"
  spec.version = Pakyow::VERSION
  spec.summary = "Pakyow Presenter"
  spec.description = "Views and presentation for Pakyow"

  spec.author = "Bryan Powell"
  spec.email = "bryan@bryanp.org"
  spec.homepage = "https://pakyow.com"

  spec.required_ruby_version = ">= 3.0.2"

  spec.license = "LGPL-3.0"

  spec.files = Dir["CHANGELOG.md", "README.md", "LICENSE", "lib/**/*"]
  spec.require_path = "lib"

  spec.add_dependency "pakyow-core", Pakyow::VERSION
  spec.add_dependency "pakyow-routing", Pakyow::VERSION
  spec.add_dependency "pakyow-support", Pakyow::VERSION

  spec.add_dependency "oga", "~> 3.3"
  spec.add_dependency "redcarpet", "~> 3.5"
end
