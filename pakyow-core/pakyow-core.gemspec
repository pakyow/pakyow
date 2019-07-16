# frozen_string_literal: true

require File.expand_path("../../lib/pakyow/version", __FILE__)

Gem::Specification.new do |spec|
  spec.name        = "pakyow-core"
  spec.version     = Pakyow::VERSION
  spec.summary     = "Pakyow Core"
  spec.description = "Core functionality for Pakyow"

  spec.author   = "Bryan Powell"
  spec.email    = "bryan@bryanp.org"
  spec.homepage = "https://pakyow.com"

  spec.required_ruby_version = ">= 2.5.0"

  spec.license = "LGPL-3.0"

  spec.files        = Dir["CHANGELOG.md", "README.md", "LICENSE", "lib/**/*"]
  spec.bindir       = "commands"
  spec.executables  = ["pakyow"]
  spec.require_path = "lib"

  spec.add_dependency "pakyow-support", Pakyow::VERSION

  spec.add_dependency "async", "~> 1.19"
  spec.add_dependency "async-http", "~> 0.46.3"
  spec.add_dependency "async-io", "~> 1.23"
  spec.add_dependency "bundler", ">= 1.17"
  spec.add_dependency "console", "~> 1.4"
  spec.add_dependency "dry-types", "~> 1.1"
  spec.add_dependency "filewatcher", "~> 1.1"
  spec.add_dependency "method_source", "~> 0.9"
  spec.add_dependency "mini_mime", "~> 1.0"
  spec.add_dependency "multipart-parser", "~> 0.1.1"
  spec.add_dependency "process-group", "~> 1.1"
  spec.add_dependency "rake", "~> 12.3"
end
