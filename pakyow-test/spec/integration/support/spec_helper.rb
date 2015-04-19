require_relative '../../../lib/pakyow-test'

require_relative 'test_app/pakyow'

Pakyow::TestHelp.setup

RSpec.configure do |config|
  config.include Pakyow::TestHelp::Helpers
end
