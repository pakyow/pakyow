# frozen_string_literal: true

require File.expand_path("../../lib/pakyow/version", __FILE__)

Gem::Specification.new do |spec|
  spec.name        = "pakyow-core"
  spec.version     = Pakyow::VERSION
  spec.summary     = "Pakyow Core"
  spec.description = "Core functionality for Pakyow"

  spec.authors  = ["Bryan Powell", "Bret Young"]
  spec.email    = "bryan@metabahn.com"
  spec.homepage = "https://pakyow.org"

  spec.required_ruby_version = ">= 2.5.0"

  spec.license = "LGPL-3.0"

  spec.files        = Dir["CHANGELOG.md", "README.md", "LICENSE", "lib/**/*"]
  spec.bindir       = "commands"
  spec.executables  = ["pakyow"]
  spec.require_path = "lib"

  spec.add_dependency "pakyow-support", Pakyow::VERSION

  spec.add_dependency "bundler", "~> 1.17"
  spec.add_dependency "dry-types", "~> 0.13"
  spec.add_dependency "filewatcher", "~> 1.1"
  spec.add_dependency "http", "~> 4.0"
  spec.add_dependency "method_source", "~> 0.9"
  spec.add_dependency "rack", "~> 2.0"
  spec.add_dependency "rake", "~> 12.3"
end
