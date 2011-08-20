version = File.read("VERSION").strip

Gem::Specification.new do |s|
  s.platform    = Gem::Platform::RUBY
  s.name        = 'pakyow-core'
  s.version     = version
  s.summary     = 'pakyow-core'
  s.description = 'pakyow-core'
  s.required_ruby_version = '>= 1.8.7'

  s.author            = 'Bryan Powell'
  s.email             = 'bryan@metabahn.com'
  s.homepage          = 'http://pakyow.com'
  s.rubyforge_project = 'pakyow-core'

  s.files        = Dir[
                        'pakyow-core/CHANGES', 
                        'pakyow-core/README', 
                        'pakyow-core/MIT-LICENSE', 
                        'pakyow-core/lib/**/*'
                      ]
                      
  s.require_path = 'pakyow-core/lib'
  
  s.bindir             = 'pakyow-core/bin'
  s.executables        = ['pakyow']
  
  s.add_dependency('rack', '>= 1.2')
end
