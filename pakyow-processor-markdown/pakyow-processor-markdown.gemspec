version = File.read(File.join(File.expand_path("../../VERSION", __FILE__))).strip
path = File.exists?('pakyow-processor-markdown') ? 'pakyow-processor-markdown' : '.'

Gem::Specification.new do |s|
  s.platform    = Gem::Platform::RUBY
  s.name        = 'pakyow-processor-markdown'
  s.version     = version
  s.summary     = 'pakyow-processor-markdown'
  s.description = 'pakyow-processor-markdown'
  s.required_ruby_version = '>= 1.9.3'

  s.authors           = ['Bryan Powell']
  s.email             = 'bryan@metabahn.com'
  s.homepage          = 'http://pakyow.com'
  s.rubyforge_project = 'pakyow-processor-markdown'

  s.files        = Dir[
                        File.join(path, 'CHANGES'),
                        File.join(path, 'README'),
                        File.join(path, 'MIT-LICENSE'),
                        File.join(path, 'lib','**','*')
                      ]

  s.require_path = File.join(path, 'lib')

  s.add_dependency('pakyow-core', version)
  s.add_dependency('pakyow-presenter', version)
  s.add_dependency('rdiscount', '~> 2.1')
end
