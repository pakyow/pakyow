start_simplecov do
  add_filter "pakyow-support/"
end

require "pakyow/data"

require "../spec/helpers/app_helpers"
require "../spec/helpers/mock_request"
require "../spec/helpers/mock_response"
require "../spec/helpers/mock_handler"

RSpec.configure do |config|
  config.include AppHelpers
end

require "../spec/context/testable_app_context"
require "../spec/context/suppressed_output_context"
