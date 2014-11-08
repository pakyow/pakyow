version = File.read(File.join(File.expand_path("../../VERSION", __FILE__))).strip
gem_path = File.exists?('pakyow-support') ? 'pakyow-support' : '.'

Gem::Specification.new do |s|
  s.platform    = Gem::Platform::RUBY
  s.name        = 'pakyow-support'
  s.version     = version
  s.summary     = 'Support code for Pakyow apps.'
  s.description = 'Supporting code used throughout Pakyow libraries.'
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

  s.add_development_dependency('rspec', '~> 3.1')
end
