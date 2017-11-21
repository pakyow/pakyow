# frozen_string_literal: true

source "https://rubygems.org"

gemspec
gemspec path: "pakyow-core"
gemspec path: "pakyow-presenter"
gemspec path: "pakyow-rake"
gemspec path: "pakyow-realtime"
gemspec path: "pakyow-support"
gemspec path: "pakyow-test"
gemspec path: "pakyow-ui"

gem "pronto", ">= 0.9"
gem "pronto-rubocop", ">= 0.9", require: false
gem "pry", ">= 0.11"
gem "rubocop", ">= 0.51"

group :test do
  gem "simplecov", ">= 0.15", require: false
  gem "simplecov-console", ">= 0.4"

  gem "rack-test", ">= 0.8", require: "rack/test"

  gem "codeclimate-test-reporter", require: false

  gem "event_emitter", ">= 0.2"
  gem "httparty", ">= 0.15"
  gem "puma", ">= 3.11"

  gem "rspec", "~> 3.7"
  gem "rspec-benchmark", "~> 0.3"
end
