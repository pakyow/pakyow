start_simplecov do
  lib_path = File.expand_path("../../lib", __FILE__)

  add_filter do |file|
    !file.filename.start_with?(lib_path)
  end

  track_files File.join(lib_path, "**/*.rb")
end

require "pakyow/data"

require_relative "../../spec/helpers/app_helpers"
require_relative "../../spec/helpers/mock_handler"

RSpec.configure do |config|
  config.include AppHelpers

  config.after do
    Pakyow.data_connections.values.flat_map(&:values).each(&:disconnect)
  end
end

require_relative "../../spec/context/testable_app_context"
require_relative "./context/migration_context"
require_relative "./context/task_context"

$data_app_boilerplate = Proc.new do
end
