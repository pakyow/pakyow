require_relative '../../spec_helper'

require_relative 'test_app/pakyow'

Pakyow::TestHelp.setup

RSpec.configure do |config|
  config.include Pakyow::TestHelp::Helpers
end
