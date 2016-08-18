require File.expand_path('../../lib/pakyow/version', __FILE__)
lib_path = File.exists?('pakyow-core') ? 'pakyow-core' : '.'

Gem::Specification.new do |spec|
  spec.name                   = 'pakyow-core'
  spec.summary                = 'Pakyow Core'
  spec.description            = 'Core routing functionality for Pakyow'
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
  spec.add_dependency('rack', '~> 1.6')

  spec.add_development_dependency('rspec', '~> 3.2')
end
