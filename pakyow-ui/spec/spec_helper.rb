start_simplecov do
  lib_path = File.expand_path("../../lib", __FILE__)

  add_filter do |file|
    !file.filename.start_with?(lib_path)
  end

  track_files File.join(lib_path, "**/*.rb")
end

require "pakyow/ui"

require_relative "../../spec/helpers/app_helpers"
require_relative "../../spec/helpers/mock_request"
require_relative "../../spec/helpers/mock_response"
require_relative "../../spec/helpers/mock_handler"

RSpec.configure do |config|
  config.include AppHelpers

  config.before do
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

def save_ui_case(case_name, path:)
  initial_response = call(path)
  expect(initial_response[0]).to eq(200)
  initial = initial_response[2].body.read

  transformation = ws_intercept do
    yield
  end

  result_response = call(path)
  expect(result_response[0]).to eq(200)
  result = result_response[2].body.read

  save_path = File.expand_path(
    "../../../pakyow-js/__tests__/support/cases/#{case_name}",
    __FILE__
  )

  FileUtils.mkdir_p(save_path)

  File.open(
    File.join(save_path, "initial.html"), "w+"
  ).write(initial)

  result_doc = Oga.parse_html(result)

  # remove templates
  result_doc.css("script").each(&:remove)

  File.open(
    File.join(save_path, "result.html"), "w+"
  ).write(result_doc.at_css("body").to_xml)

  File.open(
    File.join(save_path, "transformation.json"), "w+"
  ).write(transformation.first.to_json)

  transformation
end
