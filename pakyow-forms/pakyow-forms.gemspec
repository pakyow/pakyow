# frozen_string_literal: true

require File.expand_path("../../lib/pakyow/version", __FILE__)

Gem::Specification.new do |spec|
  spec.name        = "pakyow-forms"
  spec.version     = Pakyow::VERSION
  spec.summary     = "Pakyow Forms"
  spec.description = "Form functionality for Pakyow"

  spec.author   = "Bryan Powell"
  spec.email    = "bryan@metabahn.com"
  spec.homepage = "https://pakyow.org"

  spec.required_ruby_version = ">= 2.4.0"

  spec.license = "MIT"

  spec.files        = Dir["CHANGELOG.md", "README.md", "LICENSE", "lib/**/*"]
  spec.require_path = "lib"

  spec.add_dependency "pakyow-data", Pakyow::VERSION
  spec.add_dependency "pakyow-presenter", Pakyow::VERSION
  spec.add_dependency "pakyow-ui", Pakyow::VERSION
end
