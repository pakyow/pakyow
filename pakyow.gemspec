require File.expand_path('../lib/version', __FILE__)

Gem::Specification.new do |spec|
  spec.name                   = 'pakyow'
  spec.summary                = 'Pakyow'
  spec.description            = 'Modern web framework for Ruby'
  spec.authors                = ['Bryan Powell', 'Bret Young']
  spec.email                  = 'bryan@metabahn.com'
  spec.homepage               = 'http://pakyow.org'
  spec.version                = Pakyow::VERSION
  spec.require_path           = 'lib'
  spec.files                  = Dir['CHANGELOG.md', 'README.md', 'LICENSE', 'lib/**/*']
  spec.bindir                 = 'bin'
  spec.executables            = ['pakyow']
  spec.license                = 'MIT'
  spec.required_ruby_version  = '>= 2.0.0'

  spec.add_dependency('pakyow-support',   Pakyow::VERSION)
  spec.add_dependency('pakyow-core',      Pakyow::VERSION)
  spec.add_dependency('pakyow-presenter', Pakyow::VERSION)
  spec.add_dependency('pakyow-mailer',    Pakyow::VERSION)
  spec.add_dependency('pakyow-realtime',  Pakyow::VERSION)
  spec.add_dependency('pakyow-ui',        Pakyow::VERSION)
  spec.add_dependency('pakyow-rake',      Pakyow::VERSION)
  spec.add_dependency('pakyow-test',      Pakyow::VERSION)
  spec.add_dependency('bundler',          '~> 1.10')

  spec.add_development_dependency("rspec", "~>3.0")
end
