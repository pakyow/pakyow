GEM_NAME = 'pakyow-realtime'

version = File.read(File.join(File.expand_path("../../VERSION", __FILE__))).strip
gem_path = File.exists?(GEM_NAME) ? GEM_NAME : '.'

Gem::Specification.new do |s|
  s.platform    = Gem::Platform::RUBY
  s.name        = GEM_NAME
  s.version     = version
  s.summary     = 'Realtime capabilities for Pakyow apps.'
  s.description = 'Brings realtime capabilities to Pakyow apps by creating a pub/sub connection between client and server using websockets.'
  s.required_ruby_version = '>= 2.0.0'
  s.license     = 'MIT'

  s.authors           = ['Bryan Powell']
  s.email             = 'bryan@metabahn.com'
  s.homepage          = 'http://pakyow.com'

  s.files        = Dir[
                        File.join(gem_path, 'CHANGES'),
                        File.join(gem_path, 'README.md'),
                        File.join(gem_path, 'LICENSE'),
                        File.join(gem_path, 'lib','**','*')
                      ]

  s.require_path = File.join(gem_path, 'lib')

  s.add_dependency('websocket_parser', '~> 0.1')
  s.add_dependency('celluloid', '~> 0.16')
  s.add_dependency('redis', '~> 3.2')
  s.add_dependency('celluloid-redis', '>=0')
end
