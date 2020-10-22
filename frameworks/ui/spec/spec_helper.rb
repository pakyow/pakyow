start_simplecov do
  lib_path = File.expand_path("../../lib", __FILE__)

  add_filter do |file|
    !file.filename.start_with?(lib_path)
  end

  track_files File.join(lib_path, "**/*.rb")
end

require "htmlbeautifier"

require "pakyow/ui"

require "pakyow/data/subscribers"

require_relative "../../../spec/helpers/mock_handler"

RSpec.configure do |spec_config|
  spec_config.before :suite do
    wait_for_redis!
  end

  spec_config.before do |example|
    @excluded_frameworks = [:reflection]

    allow_any_instance_of(Pakyow::Data::Subscribers).to receive(:expire)

    if $booted
      allow_any_instance_of(Concurrent::ThreadPoolExecutor).to receive(:<<) do |_, block|
        block.call
      end

      allow_any_instance_of(Concurrent::ThreadPoolExecutor).to receive(:post) do |_, *args, &block|
        block.call(*args)
      end
    end
  end

  spec_config.before do
    Pakyow.configure do
      config.data.connections.sql[:default] = "sqlite::memory"
    end

    @default_app_def = Proc.new do
      configure do
        config.presenter.path = File.join(File.expand_path("../", __FILE__), "features/support/views")
      end

      isolated :Renderer do
        after "render" do
          # Persist subscriptions so that they are processed and intercepted.
          #
          @app.data.persist(presentables[:__socket_client_id])
        end
      end

      after "boot" do
        plugs.each do |plug|
          plug.isolated :Renderer do
            after "render" do
              # Persist subscriptions so that they are processed and intercepted.
              #
              @app.data.persist(presentables[:__socket_client_id])
            end
          end
        end
      end
    end
  end
end

$booted = false
require "pakyow/application"
Pakyow::Application.after "boot" do
  $booted = true
end

require_relative "../../../spec/context/app_context"
require_relative "../../../spec/context/suppressed_output_context"
require_relative "../../../spec/context/websocket_intercept_context"

TRANSFORMATION_IDS = [
  "e623bfc2-28a2-4929-9407-fd4c37d54b19",
  "d9d22891-3e1c-4eae-8725-170082f00785",
  "03d18512-cdd9-41fb-a3a6-af9bea8b8875",
  "f65cc0ed-e209-4b4f-a8da-529924c45508",
  "f53858dd-8342-421c-b885-78235ed95505"
]

def process_ui_case_html(html)
  @transformation_ids = html.scan(/data-t="([^"]*)"/).map { |match|
    match[0]
  }.uniq

  @transformation_ids.each_with_index do |id_to_replace, i|
    html.gsub!(id_to_replace, TRANSFORMATION_IDS[i])
  end

  html.gsub!(/name="pw-authenticity-token" content="[^"]*"/, "name=\"pw-authenticity-token\" content=\"046d2692c570018f1ea143655a284d6b0dcc4c6c292b6f13:pJtz6AYWD+8G5EDcSUgEtbtIK8loL184T2v/8//5dYw=\"")
  html.gsub!(/name="pw-socket" data-ui="socket\(global: true, endpoint: [^"]*\)"/, "name=\"pw-socket\" data-ui=\"socket(global: true, endpoint: ws://example.org:80/pw-socket?id=ece651540c6d53f8ce12833330211991702dfce3b11c50d2:CRaA6BaBQZdUKNHgOgaACEhQbQKOywdaYchDI7O6/jw=)\"")
  html.gsub!(/name="pw-authenticity-token" value="[^"]*"/, "name=\"pw-authenticity-token\" value=\"046d2692c570018f1ea143655a284d6b0dcc4c6c292b6f13:pJtz6AYWD+8G5EDcSUgEtbtIK8loL184T2v/8//5dYw=\"")
  html.gsub!(/name="pw-form" value="[^"]*"/, "name=\"pw-form\" value=\"eyJpZCI6ImQwOGQ2NDRiNzVkODUwZDU4OGMxMjhiNzIzMjM2MjY1ZWU3MTYwYjhiZGNmNWMwZSJ9~6Gf_0qrNKTx6s2hdB_JWbRWejwWqRjiaKrbcvf2DPco=\"")
  HtmlBeautifier.beautify(html)
end

def process_ui_case_transformations(transformations)
  transformations = transformations.to_json

  transformations.gsub!(/input type=\\"hidden\\" name=\\"pw-authenticity-token\\" value=\\"[^\\"]*\\"/, 'input type=\"hidden\" name=\"pw-authenticity-token\" value=\"046d2692c570018f1ea143655a284d6b0dcc4c6c292b6f13:pJtz6AYWD+8G5EDcSUgEtbtIK8loL184T2v/8//5dYw=\"')
  transformations.gsub!(/name=\\"pw-form\\" value=\\"[^\\"]*\\"/, 'name=\"pw-form\" value=\"eyJpZCI6ImQwOGQ2NDRiNzVkODUwZDU4OGMxMjhiNzIzMjM2MjY1ZWU3MTYwYjhiZGNmNWMwZSJ9~6Gf_0qrNKTx6s2hdB_JWbRWejwWqRjiaKrbcvf2DPco=\"')

  transformations = JSON.parse(transformations)

  replaced_transformation_ids = {}
  transformations.select { |transformation|
    @transformation_ids.include?(transformation["id"])
  }.sort_by { |transformation|
    @transformation_ids.index(transformation["id"])
  }.each_with_index do |transformation, i|
    if replaced_transformation_ids.key?(transformation["id"])
      transformation_id = replaced_transformation_ids[transformation["id"]]
    else
      transformation_id = TRANSFORMATION_IDS[i]
      replaced_transformation_ids[transformation["id"]] = transformation_id
    end

    transformation["id"] = transformation_id
  end

  JSON.pretty_generate(transformations)
end

def save_ui_case(example, path:)
  initial_response = call(path)
  expect(initial_response[0]).to eq(200)
  initial = initial_response[2]

  transformations = ws_intercept do
    yield
  end

  result_response = call(path)
  expect(result_response[0]).to eq(200)
  result = result_response[2]

  sleep 0.1

  case_name = example.metadata[:full_description].gsub(" ", "_").gsub(/_transforms$/, "")

  save_path = File.expand_path(
    "../../../../packages/js/__tests__/features/transformations/support/cases/#{case_name}",
    __FILE__
  )

  FileUtils.mkdir_p(save_path)

  File.open(
    File.join(save_path, "initial.html"), "w+"
  ).write(process_ui_case_html(initial))

  File.open(
    File.join(save_path, "transformations.json"), "w+"
  ).write(process_ui_case_transformations(transformations))

  File.open(
    File.join(save_path, "result.html"), "w+"
  ).write(process_ui_case_html(result))

  File.open(
    File.join(save_path, "metadata.json"), "w+"
  ).write({ path: path }.to_json)

  transformations
end
