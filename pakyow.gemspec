# frozen_string_literal: true

require File.expand_path("../lib/pakyow/version", __FILE__)

Gem::Specification.new do |spec|
  spec.name        = "pakyow"
  spec.version     = Pakyow::VERSION
  spec.summary     = "Pakyow"
  spec.description = "Modern web framework for Ruby"

  spec.authors  = ["Bryan Powell", "Bret Young"]
  spec.email    = "bryan@metabahn.com"
  spec.homepage = "https://pakyow.org"

  spec.required_ruby_version = ">= 2.4.0"

  spec.license = "LGPL-3.0"

  spec.files        = Dir["CHANGELOG.md", "README.md", "LICENSE", "lib/**/*"]
  spec.bindir       = "commands"
  spec.executables  = ["pakyow"]
  spec.require_path = "lib"

  spec.add_dependency "pakyow-assets", Pakyow::VERSION
  spec.add_dependency "pakyow-core", Pakyow::VERSION
  spec.add_dependency "pakyow-data", Pakyow::VERSION
  spec.add_dependency "pakyow-mailer", Pakyow::VERSION
  spec.add_dependency "pakyow-presenter", Pakyow::VERSION
  spec.add_dependency "pakyow-realtime", Pakyow::VERSION
  spec.add_dependency "pakyow-support", Pakyow::VERSION
  spec.add_dependency "pakyow-test", Pakyow::VERSION
  spec.add_dependency "pakyow-ui", Pakyow::VERSION

  spec.add_dependency "bundler", "~> 1.16"
  spec.add_dependency "filewatcher", "~> 1.0"
  spec.add_dependency "http", "~> 3.3"
  spec.add_dependency "method_source", "~> 0.9"
  spec.add_dependency "pastel", "~> 0.7"
  spec.add_dependency "rack", "~> 2.0"
  spec.add_dependency "rake", "~> 12.3"
  spec.add_dependency "thor", "~> 0.19"
  spec.add_dependency "tty-command", "~> 0.8"
  spec.add_dependency "tty-spinner", "~> 0.8"
end
