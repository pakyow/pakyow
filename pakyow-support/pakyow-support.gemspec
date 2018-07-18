# frozen_string_literal: true

require File.expand_path("../../lib/pakyow/version", __FILE__)

Gem::Specification.new do |spec|
  spec.name        = "pakyow-support"
  spec.version     = Pakyow::VERSION
  spec.summary     = "Pakyow Support"
  spec.description = "Supporting code for Pakyow"

  spec.author   = "Bryan Powell"
  spec.email    = "bryan@metabahn.com"
  spec.homepage = "https://pakyow.org"

  spec.required_ruby_version = ">= 2.4.0"

  spec.license = "LGPL-3.0"

  spec.files        = Dir["CHANGELOG.md", "README.md", "LICENSE", "lib/**/*"]
  spec.require_path = "lib"

  spec.add_dependency "concurrent-ruby", "~> 1.0"
  spec.add_dependency "dry-inflector", "~> 0.1"
  spec.add_dependency "pastel", "~> 0.7"
  spec.add_dependency "tty-command", "~> 0.8"
  spec.add_dependency "tty-spinner", "~> 0.8"
end
