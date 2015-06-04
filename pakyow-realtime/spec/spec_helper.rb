require 'pakyow-support'
require 'pakyow-core'
require 'celluloid'

require 'rack/test'

# disable the logger when staging
Pakyow::App.after :init do
  Pakyow.logger = Rack::NullLogger.new(app)
  Celluloid.logger = Pakyow.logger
end

# for when we don't stage the app
Celluloid.logger = Rack::NullLogger.new({})

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
