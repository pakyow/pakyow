# frozen_string_literal: true

source "https://rubygems.org"

gemspec
gemspec path: "core"
gemspec path: "support"

Pathname.new(File.expand_path("../frameworks", __FILE__)).glob("*") do |framework_path|
  gemspec path: framework_path
end

gem "memory_profiler", "~> 1.0", require: false
gem "ruby-prof", "~> 1.4", require: false
gem "benchmark-ips", "~> 2.8", require: false

gem "htmlbeautifier", "~> 1.3"
gem "pry", "~> 0.14"
gem "standard", "~> 0.12"

gem "sassc", "~> 2.4"

gem "mysql2", "~> 0.5"
gem "pg", "~> 1.2"
gem "sqlite3", "~> 1.4"

gem "bootsnap", "~> 1.7"
gem "dotenv", "~> 2.7"

group :test do
  gem "simplecov", "~> 0.21", require: false
  gem "simplecov-console", "~> 0.9"

  gem "event_emitter", "~> 0.2"
  gem "httparty", "~> 0.18"
  gem "rack", "~> 2.2"

  gem "rspec", "~> 3.10"
  gem "rspec-benchmark", "~> 0.6"
  gem "rspec-repeat", "~> 1.0"

  gem "warning", "~> 1.1"

  gem "http", "~> 4.4"
end
