require 'pakyow-test'

Pakyow::TestHelp.setup

RSpec.configure do |config|
  config.include Pakyow::TestHelp::Helpers
end
