version = File.read("VERSION").strip

Gem::Specification.new do |s|
  s.platform    = Gem::Platform::RUBY
  s.name        = 'pakyow-presenter'
  s.version     = version
  s.summary     = 'pakyow-presenter'
  s.description = 'pakyow-presenter'
  s.required_ruby_version = '>= 1.8.7'

  s.author            = 'Bryan Powell'
  s.email             = 'bryan@metabahn.com'
  s.homepage          = 'http://pakyow.com'
  s.rubyforge_project = 'pakyow-presenter'

  s.files        = Dir['pakyow-presenter/CHANGES', 'pakyow-presenter/README', 'pakyow-presenter/MIT-LICENSE', 'pakyow-presenter/lib/**/*']
  s.require_path = 'pakyow-presenter/lib'
  
  s.add_dependency('pakyow-core', "=#{version}")
  s.add_dependency('nokogiri', '>= 1.4')
end
