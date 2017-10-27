require File.expand_path('../../lib/pakyow/version', __FILE__)
lib_path = File.exists?('pakyow-mailer') ? 'pakyow-mailer' : '.'

Gem::Specification.new do |spec|
  spec.name                   = 'pakyow-mailer'
  spec.summary                = 'Pakyow Mailer'
  spec.description            = 'Mailers for Pakyow'
  spec.authors                = ['Bryan Powell', 'Bret Young']
  spec.email                  = 'bryan@metabahn.com'
  spec.homepage               = 'http://pakyow.org'
  spec.version                = Pakyow::VERSION
  spec.require_path           = File.join(lib_path, 'lib')
  spec.files                  = Dir[
                                  File.join(lib_path, 'CHANGELOG.md'),
                                  File.join(lib_path, 'README.md'),
                                  File.join(lib_path, 'LICENSE'),
                                  File.join(lib_path, 'lib/**/*')
                                ]
  spec.license                = 'MIT'
  spec.required_ruby_version  = '>= 2.0.0'

  spec.add_dependency('pakyow-support', Pakyow::VERSION)
  spec.add_dependency('pakyow-core', Pakyow::VERSION)
  spec.add_dependency('pakyow-presenter', Pakyow::VERSION)
  spec.add_dependency('mail', '~> 2.6')
  spec.add_dependency('premailer', '1.10')

  spec.add_development_dependency('minitest', '~> 5.6')
end
