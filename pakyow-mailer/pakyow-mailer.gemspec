# frozen_string_literal: true

require File.expand_path("../../lib/pakyow/version", __FILE__)

Gem::Specification.new do |spec|
  spec.name        = "pakyow-mailer"
  spec.version     = Pakyow::VERSION
  spec.summary     = "Pakyow Mailer"
  spec.description = "Mailers for Pakyow"

  spec.authors  = ["Bryan Powell", "Bret Young"]
  spec.email    = "bryan@metabahn.com"
  spec.homepage = "https://pakyow.org"

  spec.required_ruby_version = ">= 2.4.0"

  spec.license = "LGPL-3.0"

  spec.files        = Dir["CHANGELOG.md", "README.md", "LICENSE", "lib/**/*"]
  spec.require_path = "lib"

  spec.add_dependency "pakyow-assets", Pakyow::VERSION
  spec.add_dependency "pakyow-presenter", Pakyow::VERSION
  spec.add_dependency "pakyow-routing", Pakyow::VERSION
  spec.add_dependency "pakyow-support", Pakyow::VERSION

  spec.add_dependency "css_parser", "~> 1.6"
  spec.add_dependency "htmlentities", "~> 4.3"
  spec.add_dependency "mail", "~> 2.7"
  spec.add_dependency "oga", "~> 2.15"
end
