start_simplecov do
  lib_path = File.expand_path("../../lib", __FILE__)

  add_filter do |file|
    !file.filename.start_with?(lib_path)
  end

  track_files File.join(lib_path, "**/*.rb")
end

require "pakyow/reflection"

require_relative "../../spec/helpers/mock_handler"

RSpec.configure do |spec_config|
  spec_config.before do
    Pakyow.after :configure do
      Pakyow.config.data.connections.sql[:default]  = "sqlite://"
    end

    @default_app_def = Proc.new do
      configure do
        config.presenter.path = File.join(
          File.expand_path("../", __FILE__),
          "features/support/views"
        )
      end
    end
  end
end

require_relative "../../spec/context/app_context"
require_relative "./context/mirror_context"

RSpec.shared_context "reflectable app" do
  include_context "app"

  let :app_init do |example|
    example_type = File.expand_path(example.file_path).gsub(File.expand_path("../", __FILE__), "").split("/")[1]
    local_frontend_test_case = frontend_test_case
    local_reflected_app_init = reflected_app_init

    Proc.new do
      instance_exec(&local_reflected_app_init)

      if local_frontend_test_case
        after :initialize, priority: :high do
          state(:templates) << Pakyow::Presenter::Templates.new(
            :case, File.join(
              File.expand_path("../", __FILE__), example_type,
              "support/cases/#{local_frontend_test_case}"
            ),
          ).tap do |case_templates|
            if app_templates = state(:templates).find { |templates| templates.name == :default }
              case_templates.paths.each do |path|
                case_info = case_templates.info(path, false)

                # Use the app's layout, if available.
                #
                if app_templates.layouts.include?(case_info[:page].info(:layout))
                  case_info[:layout] = app_templates.layouts[case_info[:page].info(:layout)]
                end
              end
            end
          end
        end
      end

      controller :authenticity, "/authenticity" do
        default do
          send connection.verifier.sign(authenticity_client_id)
        end
      end
    end
  end

  let :frontend_test_case do
    # intentionally empty
  end

  let :reflected_app_init do
    Proc.new {}
  end
end
