source 'https://rubygems.org'

gemspec

gem 'rake', '~> 11.1'
gem 'rack', '~> 1.6'

# presenter
gem 'oga', '~> 2.3.0'

# mail
gem 'mail', '~> 2.6'
gem 'premailer', '~> 1.8'

# realtime
gem 'websocket', '~> 1.2'
gem 'redis', '~> 3.2'

group :test do
  gem 'minitest', '~> 5.6'
  gem 'rspec', '~> 3.2'
  gem 'pry', '~> 0.10'

  gem 'simplecov', '~> 0.10', require: false, group: :test
  gem 'simplecov-console', '~> 0.2'

  gem 'rack-test', '~> 0.6', require: 'rack/test'

  gem 'codeclimate-test-reporter', require: false
  
  gem 'websocket-client-simple', '~> 0.3'
  gem 'httparty', '~> 0.14'
  gem 'puma', '~> 3.6'
end

group :development do
  gem 'guard-rspec', '~> 4.6'
  gem 'rubocop', '~> 0.34'
end
