require 'pakyow-routing'
require 'pakyow-support'
require 'rack/test'

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
