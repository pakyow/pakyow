version = File.read(File.join(File.expand_path("../../VERSION", __FILE__))).strip
core_path = File.exists?('pakyow-ui') ? 'pakyow-ui' : '.'

Gem::Specification.new do |s|
  s.platform    = Gem::Platform::RUBY
  s.name        = 'pakyow-ui'
  s.version     = version
  s.summary     = 'Realtime UI for Pakyow apps.'
  s.description = 'Brings modern, realtime UIs to Pakyow apps.'
  s.required_ruby_version = '>= 2.0.0'
  s.license     = 'MIT'

  s.authors           = ['Bryan Powell']
  s.email             = 'bryan@metabahn.com'
  s.homepage          = 'http://pakyow.com'

  s.files        = Dir[
                        File.join(core_path, 'CHANGES'),
                        File.join(core_path, 'README.md'),
                        File.join(core_path, 'LICENSE'),
                        File.join(core_path, 'lib','**','*')
                      ]

  s.require_path = File.join(core_path, 'lib')

  s.add_dependency('pakyow-support', version)
  s.add_dependency('pakyow-core', version)
  s.add_dependency('pakyow-presenter', version)
  s.add_dependency('pakyow-realtime', version)

  s.add_development_dependency('minitest', '~> 5.6')
  s.add_development_dependency('rspec', '~> 3.2')
end
