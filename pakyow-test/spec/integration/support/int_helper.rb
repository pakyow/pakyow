require_relative '../../spec_helper'

Pakyow::TestHelp.setup('./spec/integration/support/test_app/pakyow')

RSpec.configure do |config|
  config.include Pakyow::TestHelp::Helpers
end
