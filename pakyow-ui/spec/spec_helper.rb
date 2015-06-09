require '/users/bryanp/code/pakyow/libs/pakyow/pakyow-support/lib/pakyow-support'
require '/users/bryanp/code/pakyow/libs/pakyow/pakyow-core/lib/pakyow-core'
require '/users/bryanp/code/pakyow/libs/pakyow/pakyow-presenter/lib/pakyow-presenter'
require '/users/bryanp/code/pakyow/libs/pakyow/pakyow-realtime/lib/pakyow-realtime'

require 'rack/test'

# disable the logger when staging
Pakyow::App.after :init do
  Pakyow.logger = Rack::NullLogger.new(app)
  Celluloid.logger = Pakyow.logger
end

# handle errors that occur
Pakyow::App.after :error do
  # puts request.error.message
  # puts request.error.backtrace

  raise request.error
end

# for when we don't stage the app
Celluloid.logger = Rack::NullLogger.new({})

if ENV['COVERAGE']
  require 'simplecov'
  require 'simplecov-console'
  SimpleCov.formatter = SimpleCov::Formatter::Console
  SimpleCov.start
end

module PerformedMutations
  def self.perform(name, view = nil, data = nil)
    performed[name] = {
      view: view,
      data: data,
    }

    view
  end

  def self.performed
    @performed ||= {}
  end

  def self.reset
    @performed = {}
  end
end
