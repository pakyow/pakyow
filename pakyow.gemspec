require File.expand_path("../lib/pakyow/version", __FILE__)

Gem::Specification.new do |spec|
  spec.name                   = "pakyow"
  spec.version                = Pakyow::VERSION

  spec.license                = "MIT"
  spec.summary                = "Pakyow"
  spec.description            = "Modern web framework for Ruby"
  spec.authors                = ["Bryan Powell", "Bret Young"]
  spec.email                  = "bryan@metabahn.com"
  spec.homepage               = "https://www.pakyow.org"

  spec.require_path           = "lib"
  spec.files                  = Dir["CHANGELOG.md", "README.md", "LICENSE", "lib/**/*"]
  spec.bindir                 = "commands"
  spec.executables            = ["pakyow"]
  spec.required_ruby_version  = ">= 2.3.0"

  spec.add_dependency("pakyow-support",   Pakyow::VERSION)
  spec.add_dependency("pakyow-core",      Pakyow::VERSION)
  spec.add_dependency("pakyow-presenter", Pakyow::VERSION)
  spec.add_dependency("pakyow-mailer",    Pakyow::VERSION)
  spec.add_dependency("pakyow-realtime",  Pakyow::VERSION)
  spec.add_dependency("pakyow-ui",        Pakyow::VERSION)
  spec.add_dependency("pakyow-rake",      Pakyow::VERSION)
  spec.add_dependency("pakyow-test",      Pakyow::VERSION)
  spec.add_dependency("bundler",          "~> 1.13")
  spec.add_dependency("thor",             "~> 0.19")
  spec.add_dependency("rack-protection",  "~> 1.5")

  spec.add_development_dependency("rspec", "~> 3.5")
  spec.add_development_dependency("pry", "~> 0.10")
  spec.add_development_dependency("guard-rspec", "~> 4.6")
  spec.add_development_dependency("rubocop", "~> 0.34")
end
