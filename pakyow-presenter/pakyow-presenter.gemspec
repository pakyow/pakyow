version = File.read(File.join(File.expand_path("../../VERSION", __FILE__))).strip
presenter_path = File.exists?('pakyow-presenter') ? 'pakyow-presenter' : '.'

Gem::Specification.new do |s|
  s.platform    = Gem::Platform::RUBY
  s.name        = 'pakyow-presenter'
  s.version     = version
  s.summary     = 'pakyow-presenter'
  s.description = 'pakyow-presenter'
  s.required_ruby_version = '>= 1.8.7'

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
  
  s.add_dependency('pakyow-core', version)
  s.add_dependency('nokogiri', '~> 1.5')
  s.add_development_dependency('shoulda', '~> 2.11')
end
