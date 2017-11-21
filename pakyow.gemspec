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

  spec.license = "MIT"

  spec.files        = Dir["CHANGELOG.md", "README.md", "LICENSE", "lib/**/*"]
  spec.bindir       = "commands"
  spec.executables  = ["pakyow"]
  spec.require_path = "lib"

  spec.add_dependency "pakyow-core", Pakyow::VERSION
  spec.add_dependency "pakyow-mailer", Pakyow::VERSION
  spec.add_dependency "pakyow-presenter", Pakyow::VERSION
  spec.add_dependency "pakyow-rake", Pakyow::VERSION
  spec.add_dependency "pakyow-realtime", Pakyow::VERSION
  spec.add_dependency "pakyow-support", Pakyow::VERSION
  spec.add_dependency "pakyow-test", Pakyow::VERSION
  spec.add_dependency "pakyow-ui", Pakyow::VERSION

  spec.add_dependency "bundler", "~> 1.13"
  spec.add_dependency "listen", "~> 3.1"
  spec.add_dependency "pastel", "~> 0.7"
  spec.add_dependency "rack", "~> 2.0"
  spec.add_dependency "rack-protection", "~> 1.5"
  spec.add_dependency "thor", "~> 0.20"
end
