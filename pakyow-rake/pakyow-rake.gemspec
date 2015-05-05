version = File.read(File.join(File.expand_path("../../VERSION", __FILE__))).strip
path = File.exists?('pakyow-rake') ? 'pakyow-rake' : '.'

Gem::Specification.new do |s|
  s.platform    = Gem::Platform::RUBY
  s.name        = 'pakyow-rake'
  s.version     = version
  s.summary     = 'Rake tasks for Pakyow apps.'
  s.description = 'A collection of rake tasks for Pakyow apps.'
  s.required_ruby_version = '>= 2.0.0'
  s.license     = 'MIT'

  s.authors           = ['Bryan Powell']
  s.email             = 'bryan@metabahn.com'
  s.homepage          = 'http://pakyow.com'
  s.rubyforge_project = 'pakyow-rake'

  s.files        = Dir[
                        File.join(path, 'CHANGES'),
                        File.join(path, 'README'),
                        File.join(path, 'LICENSE'),
                        File.join(path, 'lib','**','*')
                      ]

  s.require_path = File.join(path, 'lib')

  s.add_dependency('pakyow-support', version)
  s.add_dependency('pakyow-core', version)
  s.add_dependency('pakyow-presenter', version)
  s.add_dependency('rake', '~> 10.4')
end
