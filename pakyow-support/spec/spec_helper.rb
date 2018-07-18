start_simplecov do
  lib_path = File.expand_path("../../lib", __FILE__)

  add_filter do |file|
    !file.filename.start_with?(lib_path)
  end

  track_files File.join(lib_path, "**/*.rb")
end

require_relative "../../spec/helpers/output_helpers"

RSpec.configure do |config|
  config.include OutputHelpers
end
