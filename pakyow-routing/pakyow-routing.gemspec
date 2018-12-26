# frozen_string_literal: true

require File.expand_path("../../lib/pakyow/version", __FILE__)

Gem::Specification.new do |spec|
  spec.name        = "pakyow-routing"
  spec.version     = Pakyow::VERSION
  spec.summary     = "Pakyow Routing"
  spec.description = "Routing functionality for Pakyow"

  spec.authors  = ["Bryan Powell", "Bret Young"]
  spec.email    = "bryan@metabahn.com"
  spec.homepage = "https://pakyow.org"

  spec.required_ruby_version = ">= 2.5.0"

  spec.license = "LGPL-3.0"

  spec.files        = Dir["CHANGELOG.md", "README.md", "LICENSE", "lib/**/*"]
  spec.require_path = "lib"

  spec.add_dependency "pakyow-core", Pakyow::VERSION
  spec.add_dependency "pakyow-support", Pakyow::VERSION
end
