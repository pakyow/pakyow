require File.expand_path('../../lib/pakyow/version', __FILE__)
lib_path = File.exists?('pakyow-realtime') ? 'pakyow-realtime' : '.'

Gem::Specification.new do |spec|
  spec.name                   = 'pakyow-realtime'
  spec.summary                = 'Pakyow Realtime'
  spec.description            = 'WebSockets and realtime channels for Pakyow'
  spec.author                 = 'Bryan Powell'
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
  spec.add_dependency('websocket', '~> 1.2')
  spec.add_dependency('redis', '~> 3.2')
  spec.add_dependency('nio4r', '~> 1.2')
end
