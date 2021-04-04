# frozen_string_literal: true

require File.expand_path("../lib/pakyow/version", __FILE__)

Gem::Specification.new do |spec|
  spec.name = "pakyow-core"
  spec.version = Pakyow::VERSION
  spec.summary = "Pakyow Core"
  spec.description = "Core functionality for Pakyow"

  spec.author = "Bryan Powell"
  spec.email = "bryan@bryanp.org"
  spec.homepage = "https://pakyow.com"

  spec.required_ruby_version = ">= 2.7.2"

  spec.license = "LGPL-3.0"

  spec.files = Dir["CHANGELOG.md", "README.md", "LICENSE", "lib/**/*"]
  spec.bindir = "commands"
  spec.executables = ["pakyow"]
  spec.require_path = "lib"

  spec.add_dependency "pakyow-support", Pakyow::VERSION

  spec.add_dependency "core-async", "~> 0.5.0"
  spec.add_dependency "core-watch", "~> 0.0.0"

  spec.add_dependency "async-http", "~> 0.54.1"
  spec.add_dependency "async-io", "~> 1.30"
  spec.add_dependency "bundler", "~> 2.2"
  spec.add_dependency "console", "~> 1.10"
  spec.add_dependency "dry-types", "~> 1.5"
  spec.add_dependency "method_source", "~> 1.0"
  spec.add_dependency "mini_mime", "~> 1.0"
  spec.add_dependency "multipart-parser", "~> 0.1.1"
  spec.add_dependency "rake", "~> 13.0"
  spec.add_dependency "tty-command", "~> 0.10.0"
end
