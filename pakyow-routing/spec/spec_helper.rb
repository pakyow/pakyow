start_simplecov do
  lib_path = File.expand_path("../../lib", __FILE__)

  add_filter do |file|
    !file.filename.start_with?(lib_path)
  end

  track_files File.join(lib_path, "**/*.rb")
end

require "pakyow/routing"

require_relative "../../spec/helpers/mock_handler"

RSpec.configure do |config|
end

require_relative "../../spec/context/testable_app_context"
require_relative "../../spec/context/suppressed_output_context"
