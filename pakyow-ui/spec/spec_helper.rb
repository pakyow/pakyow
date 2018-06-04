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

def process_ui_case_html(html)
  html.gsub!(/<html data-t=".*">/, "<html data-t=\"61aeb4df92f094a6ae2e1c0a569e480d2244c8fe\">")
  html.gsub!(/<meta name="pw-authenticity-token" content=".*">/, "<meta name=\"pw-authenticity-token\" content=\"046d2692c570018f1ea143655a284d6b0dcc4c6c292b6f13:pJtz6AYWD+8G5EDcSUgEtbtIK8loL184T2v/8//5dYw=\">")
  html.gsub!(/<meta name="pw-connection-id" content=".*">/, "<meta name=\"pw-connection-id\" content=\"ece651540c6d53f8ce12833330211991702dfce3b11c50d2:CRaA6BaBQZdUKNHgOgaACEhQbQKOywdaYchDI7O6/jw=\">")
  html.gsub!(/<input type="hidden" name="authenticity_token" value=".*">/, "<input type=\"hidden\" name=\"authenticity_token\" value=\"046d2692c570018f1ea143655a284d6b0dcc4c6c292b6f13:pJtz6AYWD+8G5EDcSUgEtbtIK8loL184T2v/8//5dYw=\">")
  HtmlBeautifier.beautify(html)
end

def process_ui_case_transformations(transformations)
  transformations = JSON.parse(transformations.to_json)
  transformations.each do |transformation|
    transformation["id"] = "61aeb4df92f094a6ae2e1c0a569e480d2244c8fe"
  end

  JSON.pretty_generate(transformations)
end

def save_ui_case(example, path:)
  initial_response = call(path)
  expect(initial_response[0]).to eq(200)
  initial = initial_response[2].body.read

  transformations = ws_intercept do
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
  ).write(process_ui_case_html(initial))

  File.open(
    File.join(save_path, "result.html"), "w+"
  ).write(process_ui_case_html(result))

  File.open(
    File.join(save_path, "transformations.json"), "w+"
  ).write(process_ui_case_transformations(transformations))

  File.open(
    File.join(save_path, "metadata.json"), "w+"
  ).write({ path: path }.to_json)

  transformations
end
