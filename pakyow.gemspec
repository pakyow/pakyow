version = File.read(File.expand_path("../VERSION", __FILE__)).strip

Gem::Specification.new do |s|
  s.platform    = Gem::Platform::RUBY
  s.name        = 'pakyow'
  s.version     = version
  s.summary     = 'Web application framework.'
  s.description = 'Pakyow is an open-source framework for building apps that embrace the web and encourages a development process that\'s friendly to both designers and developers. It\'s built for getting along.'
  s.license     = 'MIT'

  s.required_ruby_version     = '>= 1.9.3'
  s.required_rubygems_version = ">= 1.8.11"

  s.authors           = ['Bryan Powell', 'Bret Young']
  s.email             = 'bryan@metabahn.com'
  s.homepage          = 'http://pakyow.com'
  s.rubyforge_project = 'pakyow'

  s.files        = Dir['README', 'MIT-LICENSE', 'lib/**/*']
  s.require_path = 'lib'

  s.bindir             = 'bin'
  s.executables        = ['pakyow']

  s.add_dependency('pakyow-core',       version)
  s.add_dependency('pakyow-presenter',  version)
  s.add_dependency('pakyow-mailer',     version)
  # s.add_dependency('pakyow-rake',       version)

  s.add_dependency('bundler',           '~> 1.5')
end
