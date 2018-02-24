i = ARGV.index("--pattern")

# Works around an annoying problem where this helper is required when running
# specs for other libraries, such as pakyow-core.
#
if i.nil? || ARGV[i + 1].start_with?(File.expand_path("../", __FILE__))
  start_simplecov do
    lib_path = File.expand_path("../../lib", __FILE__)

    add_filter do |file|
      !file.filename.start_with?(lib_path)
    end

    track_files File.join(lib_path, "**/*.rb")
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
end
