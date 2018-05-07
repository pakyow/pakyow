start_simplecov do
  lib_path = File.expand_path("../../lib", __FILE__)

  add_filter do |file|
    !file.filename.start_with?(lib_path)
  end

  track_files File.join(lib_path, "**/*.rb")
end

require "pakyow/forms"

require_relative "../../spec/helpers/app_helpers"
require_relative "../../spec/helpers/mock_request"
require_relative "../../spec/helpers/mock_response"
require_relative "../../spec/helpers/mock_handler"

RSpec.configure do |config|
  config.include AppHelpers
end

require_relative "../../spec/context/testable_app_context"

$forms_app_boilerplate = Proc.new do
  configure do
    config.presenter.path = File.join(File.expand_path("../", __FILE__), "features/support/views")
    config.presenter.embed_authenticity_token = false
  end
end
