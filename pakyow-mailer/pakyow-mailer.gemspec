version = File.read(File.join(File.expand_path("../../VERSION", __FILE__))).strip
presenter_path = File.exists?('pakyow-mailer') ? 'pakyow-mailer' : '.'

Gem::Specification.new do |s|
  s.platform    = Gem::Platform::RUBY
  s.name        = 'pakyow-mailer'
  s.version     = version
  s.summary     = 'A library for delivering Pakyow views as mail.'
  s.description = 'A library for delivering Pakyow views as mail.'
  s.required_ruby_version = '>= 1.9.3'
  s.license     = 'MIT'

  s.authors           = ['Bryan Powell', 'Bret Young']
  s.email             = 'bryan@metabahn.com'
  s.homepage          = 'http://pakyow.com'
  s.rubyforge_project = 'pakyow-mailer'

  s.files        = Dir[
                        File.join(presenter_path, 'CHANGES'),
                        File.join(presenter_path, 'README'),
                        File.join(presenter_path, 'MIT-LICENSE'),
                        File.join(presenter_path, 'lib','**','*')
                      ]

  s.require_path = File.join(presenter_path, 'lib')

  s.add_dependency('pakyow-core', version)
  s.add_dependency('pakyow-presenter', version)
  s.add_dependency('mail', '~> 2.5')
  s.add_dependency('premailer', '~> 1.7')

  s.add_development_dependency('minitest', '~> 5.0')
end
