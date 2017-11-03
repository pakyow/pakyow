start_simplecov do
  add_filter "pakyow-support/"
end

require "pakyow"

require "helpers/app_helpers"
require "helpers/mock_request"
require "helpers/mock_response"
require "helpers/mock_handler"

RSpec.configure do |config|
  config.include AppHelpers
end

require "context/testable_app_context"
require "context/suppressed_output_context"
