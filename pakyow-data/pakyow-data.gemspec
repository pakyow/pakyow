# frozen_string_literal: true

require File.expand_path("../../lib/pakyow/version", __FILE__)
lib_path = File.exists?("pakyow-data") ? "pakyow-data" : "."

Gem::Specification.new do |spec|
  spec.name                   = "pakyow-data"
  spec.summary                = "Pakyow Data"
  spec.description            = "Data layer for Pakyow"
  spec.author                 = "Bryan Powell"
  spec.email                  = "bryan@metabahn.com"
  spec.homepage               = "http://pakyow.org"
  spec.version                = Pakyow::VERSION
  spec.require_path           = File.join(lib_path, "lib")
  spec.files                  = Dir[
                                  File.join(lib_path, "CHANGELOG.md"),
                                  File.join(lib_path, "README.md"),
                                  File.join(lib_path, "LICENSE"),
                                  File.join(lib_path, "lib/**/*")
                                ]
  spec.license                = "MIT"
  spec.required_ruby_version  = ">= 2.0.0"

  spec.add_dependency("concurrent-ruby", "~> 1.0")
  spec.add_dependency("pakyow-support", Pakyow::VERSION)
  spec.add_dependency("rom")
  spec.add_dependency("rom-sql")

  spec.add_development_dependency("rspec", "~> 3.2")
end
