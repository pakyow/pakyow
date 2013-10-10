version = File.read(File.expand_path("../VERSION", __FILE__)).strip

Gem::Specification.new do |s|
  s.platform    = Gem::Platform::RUBY
  s.name        = 'pakyow'
  s.version     = version
  s.summary     = 'Punch packing application framework.'
  s.description = ''

  s.required_ruby_version     = '>= 1.9.3'
  s.required_rubygems_version = ">= 1.8.11"

  s.authors           = ['Bryan Powell', 'Bret Young']
  s.email             = 'bryan@metabahn.com'
  s.homepage          = 'http://pakyow.com'
  s.rubyforge_project = 'pakyow'

  s.files        = Dir['README', 'MIT-LICENSE', 'lib/**/*']
  s.require_path = 'lib'

  s.add_dependency('pakyow-core',       version)
  s.add_dependency('pakyow-presenter',  version)
  s.add_dependency('pakyow-mailer',     version)
  s.add_dependency('pakyow-rake',       version)

  s.add_dependency('bundler',           '>= 1.3.0')
end
