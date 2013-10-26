version = File.read(File.join(File.expand_path("../../VERSION", __FILE__))).strip
core_path = File.exists?('pakyow-core') ? 'pakyow-core' : '.'

Gem::Specification.new do |s|
  s.platform    = Gem::Platform::RUBY
  s.name        = 'pakyow-core'
  s.version     = version
  s.summary     = 'Core functionality for Pakyow applications.'
  s.description = 'Core functionality for Pakyow applications, including routing and middleware.'
  s.required_ruby_version = '>= 1.9.3'
  s.license     = 'MIT'

  s.authors           = ['Bryan Powell', 'Bret Young']
  s.email             = 'bryan@metabahn.com'
  s.homepage          = 'http://pakyow.com'
  s.rubyforge_project = 'pakyow-core'

  s.files        = Dir[
                        File.join(core_path, 'CHANGES'),
                        File.join(core_path, 'README'),
                        File.join(core_path, 'MIT-LICENSE'),
                        File.join(core_path, 'lib','**','*')
                      ]

  s.require_path = File.join(core_path, 'lib')

  s.add_dependency('rack', '~> 1.5')

  s.add_development_dependency('minitest', '~> 5.0')
end
