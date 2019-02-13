# frozen_string_literal: true

source "https://rubygems.org"

gemspec
gemspec path: "pakyow-assets"
gemspec path: "pakyow-core"
gemspec path: "pakyow-data"
gemspec path: "pakyow-form"
gemspec path: "pakyow-presenter"
gemspec path: "pakyow-realtime"
gemspec path: "pakyow-routing"
gemspec path: "pakyow-support"
gemspec path: "pakyow-ui"

gem "htmlbeautifier", ">= 1.3"
gem "pronto", ">= 0.9"
gem "pronto-rubocop", ">= 0.9", require: false
gem "pry", ">= 0.11"
gem "pry-byebug", ">= 3.6"
gem "rubocop", ">= 0.51"

group :test do
  gem "simplecov", ">= 0.16", require: false
  gem "simplecov-console", ">= 0.4"

  gem "rack-test", ">= 0.8", require: "rack/test"

  gem "codeclimate-test-reporter", require: false

  gem "event_emitter", ">= 0.2"
  gem "httparty", ">= 0.16"
  gem "puma", ">= 3.12"

  gem "rspec", "~> 3.8"
  gem "rspec-benchmark", "~> 0.4"

  gem "warning", "~> 0.10"

  gem "sassc", "~> 2.0"

  gem "mysql2", "~> 0.5"
  gem "pg", "~> 1.1"
  gem "sqlite3", "~> 1.3"

  gem "bootsnap", "~> 1.3"
  gem "dotenv", "~> 2.5"

  gem "memory_profiler", "~> 0.9", require: false
  gem "ruby-prof", "~> 0.17", require: false
end
