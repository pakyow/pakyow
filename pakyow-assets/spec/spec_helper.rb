start_simplecov do
  lib_path = File.expand_path("../../lib", __FILE__)

  add_filter do |file|
    !file.filename.start_with?(lib_path)
  end

  track_files File.join(lib_path, "**/*.rb")
end

require "pakyow/assets"

require_relative "../../spec/helpers/mock_handler"

RSpec.configure do |spec_config|
  spec_config.before do
    @default_app_def = Proc.new do
      configure do
        config.root = File.expand_path("../support/app", __FILE__)
      end
    end
  end
end

require_relative "../../spec/context/app_context"
