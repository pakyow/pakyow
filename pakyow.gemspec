version = File.read(File.expand_path("../VERSION", __FILE__)).strip

Gem::Specification.new do |s|
  s.platform    = Gem::Platform::RUBY
  s.name        = 'pakyow'
  s.version     = version
  s.summary     = 'Web app platform.'
  s.description = "Pakyow is an open-source platform for the modern web. Build web-based apps faster with a view-first development process that's friendly to everyone – whether you're a designer or a developer. It's for getting along."
  s.license     = 'MIT'

  s.required_ruby_version     = '>= 2.0.0'

  s.authors           = ['Bryan Powell', 'Bret Young']
  s.email             = 'bryan@metabahn.com'
  s.homepage          = 'http://pakyow.com'
  s.rubyforge_project = 'pakyow'

  s.files        = Dir['README', 'MIT-LICENSE', 'lib/**/*']
  s.require_path = 'lib'

  s.bindir             = 'bin'
  s.executables        = ['pakyow']

  s.add_dependency('pakyow-support',    version)
  s.add_dependency('pakyow-core',       version)
  s.add_dependency('pakyow-presenter',  version)
  s.add_dependency('pakyow-mailer',     version)
  s.add_dependency('pakyow-rake',       version)
  s.add_dependency('pakyow-test',       version)

  s.add_dependency('bundler',           '~> 1.5')
end
