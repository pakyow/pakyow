require 'pakyow-support'
require 'pakyow-core'
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
