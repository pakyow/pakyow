source "https://rubygems.org"

gemspec
gemspec path: "pakyow-core"

gem "rake", "~> 11.1"
gem "rack", "~> 2.0"

# presenter
gem "oga", "~> 2.6"

# mail
gem "mail", "~> 2.6"
gem "premailer", "1.10"

# realtime
gem "websocket", "~> 1.2"
gem "redis", "~> 3.2"

group :test do
  gem "minitest", "~> 5.6"

  gem "simplecov", "~> 0.10", require: false, group: :test
  gem "simplecov-console", "~> 0.2"

  gem "rack-test", "~> 0.6", require: "rack/test"

  gem "codeclimate-test-reporter", require: false

  gem "event_emitter", "~> 0.2"
  gem "httparty", "~> 0.14"
  gem "puma", "~> 3.6"
end
