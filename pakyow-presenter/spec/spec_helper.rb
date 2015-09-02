require 'rspec'
require 'pry'
require 'pp'

require File.expand_path('../../../pakyow-support/lib/pakyow-support', __FILE__)
require File.expand_path('../../../pakyow-core/lib/pakyow-core', __FILE__)
require File.expand_path('../../lib/pakyow-presenter', __FILE__)

# disable the logger when staging
Pakyow::App.after :init do
  Pakyow.logger = Rack::NullLogger.new(app)
end
