version = File.read(File.expand_path("../VERSION", __FILE__)).strip

Gem::Specification.new do |s|
  s.platform    = Gem::Platform::RUBY
  s.name        = 'pakyow'
  s.version     = version
  s.summary     = 'Pakyow web application framework.'
  s.description = 'Pakyow web application framework.'

  s.required_ruby_version     = '>= 1.8.7'
  s.required_rubygems_version = ">= 1.3.6"

  s.author            = 'Bryan Powell'
  s.email             = 'bryan@metabahn.com'
  s.homepage          = 'http://pakyow.com'
  s.rubyforge_project = 'pakyow'
  
  s.files        = Dir['README', 'MIT-LICENSE', 'lib/**/*']
  s.require_path = 'lib'
  
  s.add_dependency('pakyow-core', "=#{version}")
  s.add_dependency('pakyow-presenter', "=#{version}")
end
