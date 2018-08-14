start_simplecov do
  lib_path = File.expand_path("../../lib", __FILE__)

  add_filter do |file|
    !file.filename.start_with?(lib_path)
  end

  track_files File.join(lib_path, "**/*.rb")
end

require "pakyow"

require_relative "../../spec/helpers/app_helpers"
require_relative "../../spec/helpers/mock_handler"
require_relative "../../spec/helpers/output_helpers"
require_relative "../../spec/helpers/command_helpers"

RSpec.configure do |config|
  config.include AppHelpers
  config.include OutputHelpers
  config.include CommandHelpers
end

require_relative "../../spec/context/testable_app_context"
require_relative "../../spec/context/testable_command_context"
require_relative "../../spec/context/suppressed_output_context"
