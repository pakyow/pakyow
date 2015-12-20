require 'pakyow-support'
require 'pakyow-core'
require 'concurrent'

require 'rack/test'

# disable the logger when staging
Pakyow::App.after :init do
  Pakyow.logger = Rack::NullLogger.new(self)
end

if ENV['COVERAGE']
  require 'simplecov'
  require 'simplecov-console'
  SimpleCov.formatter = SimpleCov::Formatter::Console
  SimpleCov.start
end

def redis_available?
  Redis.new.get('test')
  true
rescue Redis::CannotConnectError
  false
end
