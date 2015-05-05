version = File.read(File.join(File.expand_path("../../VERSION", __FILE__))).strip
gem_path = File.exists?('pakyow-test') ? 'pakyow-test' : '.'

Gem::Specification.new do |s|
  s.platform    = Gem::Platform::RUBY
  s.name        = 'pakyow-test'
  s.version     = version
  s.summary     = 'Test helpers for Pakyow apps.'
  s.description = 'Helpers for writing tests for Pakyow apps.'
  s.required_ruby_version = '>= 2.0.0'
  s.license     = 'MIT'

  s.authors           = ['Bryan Powell']
  s.email             = 'bryan@metabahn.com'
  s.homepage          = 'http://pakyow.com'

  s.files        = Dir[
                        File.join(gem_path, 'CHANGES'),
                        File.join(gem_path, 'README'),
                        File.join(gem_path, 'MIT-LICENSE'),
                        File.join(gem_path, 'lib','**','*')
                      ]

  s.require_path = File.join(gem_path, 'lib')

  s.add_development_dependency('rspec', '~> 3.2')
end
