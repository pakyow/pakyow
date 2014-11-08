version = File.read(File.join(File.expand_path("../../VERSION", __FILE__))).strip
presenter_path = File.exists?('pakyow-presenter') ? 'pakyow-presenter' : '.'

Gem::Specification.new do |s|
  s.platform    = Gem::Platform::RUBY
  s.name        = 'pakyow-presenter'
  s.version     = version
  s.summary     = 'Presenter functionality for Pakyow apps.'
  s.description = 'A library for building frontends for Pakyow apps, including templating and data binding.'
  s.required_ruby_version = '>= 2.0.0'
  s.license     = 'MIT'

  s.authors           = ['Bryan Powell', 'Bret Young']
  s.email             = 'bryan@metabahn.com'
  s.homepage          = 'http://pakyow.com'
  s.rubyforge_project = 'pakyow-presenter'

  s.files        = Dir[
                        File.join(presenter_path, 'CHANGES'),
                        File.join(presenter_path, 'README'),
                        File.join(presenter_path, 'MIT-LICENSE'),
                        File.join(presenter_path, 'lib','**','*')
                      ]

  s.require_path = File.join(presenter_path, 'lib')

  s.add_dependency('pakyow-support', version)
  s.add_dependency('pakyow-core', version)
  s.add_dependency('nokogiri', '~> 1.6')

  s.add_development_dependency('minitest', '~> 5.0')
  s.add_development_dependency('pry', '~> 0.9')
end
