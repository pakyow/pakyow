start_simplecov do
  lib_path = File.expand_path("../../lib", __FILE__)

  add_filter do |file|
    !file.filename.start_with?(lib_path)
  end

  track_files File.join(lib_path, "**/*.rb")
end

require "pakyow/routing"
require "pakyow/presenter"
require "pakyow/mailer"

require_relative "../../../spec/helpers/mock_handler"

RSpec.configure do |spec_config|
  spec_config.before do
    @default_app_def = Proc.new do
      configure do
        config.presenter.path = File.join(File.expand_path("../", __FILE__), "features/support/views")
      end
    end
  end
end

require_relative "../../../spec/context/app_context"
require_relative "../../../spec/context/suppressed_output_context"
