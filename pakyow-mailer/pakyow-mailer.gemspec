version = File.read(File.join(File.expand_path("../../VERSION", __FILE__))).strip
presenter_path = File.exists?('pakyow-mailer') ? 'pakyow-mailer' : '.'

Gem::Specification.new do |s|
  s.platform    = Gem::Platform::RUBY
  s.name        = 'pakyow-mailer'
  s.version     = version
  s.summary     = 'Mail functionality for Pakyow apps.'
  s.description = 'A library for delivering Pakyow views via email.'
  s.required_ruby_version = '>= 2.0.0'
  s.license     = 'MIT'

  s.authors           = ['Bryan Powell', 'Bret Young']
  s.email             = 'bryan@metabahn.com'
  s.homepage          = 'http://pakyow.com'
  s.rubyforge_project = 'pakyow-mailer'

  s.files        = Dir[
                        File.join(presenter_path, 'CHANGES'),
                        File.join(presenter_path, 'README'),
                        File.join(presenter_path, 'LICENSE'),
                        File.join(presenter_path, 'lib','**','*')
                      ]

  s.require_path = File.join(presenter_path, 'lib')

  s.add_dependency('pakyow-support', version)
  s.add_dependency('pakyow-core', version)
  s.add_dependency('pakyow-presenter', version)
  s.add_dependency('mail', '~> 2.6')
  s.add_dependency('premailer', '~> 1.8')

  s.add_development_dependency('minitest', '~> 5.6')
end
