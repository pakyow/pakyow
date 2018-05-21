start_simplecov do
  lib_path = File.expand_path("../../lib", __FILE__)

  add_filter do |file|
    !file.filename.start_with?(lib_path)
  end

  track_files File.join(lib_path, "**/*.rb")
end

require "htmlbeautifier"

require "pakyow/ui"

require_relative "../../spec/helpers/app_helpers"
require_relative "../../spec/helpers/mock_handler"

RSpec.configure do |config|
  config.include AppHelpers

  config.before do |example|
    Pakyow.config.data.connections.sql[:default] = "sqlite::memory"
  end
end

require_relative "../../spec/context/testable_app_context"
require_relative "../../spec/context/suppressed_output_context"
require_relative "../../spec/context/websocket_intercept_context"

$ui_app_boilerplate = Proc.new do
  configure do
    config.presenter.path = File.join(File.expand_path("../", __FILE__), "features/support/views")
  end
end

def save_ui_case(example, path:)
  initial_response = call(path)
  expect(initial_response[0]).to eq(200)
  initial = initial_response[2].body.read

  transformation = ws_intercept do
    yield
  end

  result_response = call(path)
  expect(result_response[0]).to eq(200)
  result = result_response[2].body.read

  case_name = example.metadata[:full_description].gsub(" ", "_").gsub(/_transforms$/, "")

  save_path = File.expand_path(
    "../../../pakyow-js/__tests__/features/transformations/support/cases/#{case_name}",
    __FILE__
  )

  FileUtils.mkdir_p(save_path)

  File.open(
    File.join(save_path, "initial.html"), "w+"
  ).write(HtmlBeautifier.beautify(initial))

  File.open(
    File.join(save_path, "result.html"), "w+"
  ).write(HtmlBeautifier.beautify(result))

  File.open(
    File.join(save_path, "transformations.json"), "w+"
  ).write(JSON.pretty_generate(transformation))

  transformation
end
