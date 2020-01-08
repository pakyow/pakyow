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
    Pakyow.after "configure" do
      Pakyow.config.data.connections.sql[:default]  = "sqlite://"
      Pakyow.config.data.connections.sql[:memory]  = "sqlite::memory"
    end

    @default_app_def = Proc.new do
      configure do
        config.presenter.path = File.join(
          File.expand_path("../", __FILE__),
          "support/app/frontend"
        )
      end
    end
  end
end

require_relative "../../spec/context/app_context"
require_relative "./context/mirror_context"

RSpec.shared_context "reflectable app" do
  include_context "app"

  let :app_def do |example|
    local_frontend_test_case = frontend_test_case
    local_reflected_app_def = reflected_app_def
    local_default_app_def = @default_app_def

    Proc.new do
      instance_exec(&local_default_app_def)
      instance_exec(&local_reflected_app_def)

      if local_frontend_test_case
        before "initialize.presenter" do
          @case_templates = Pakyow::Presenter::Templates.new(
            :case, File.join(
              File.expand_path("../", __FILE__),
              "support/cases/#{local_frontend_test_case}"
            ),
          )

          templates << @case_templates
        end

        after "initialize.presenter", priority: :high do
          if app_templates = templates.each.find { |templates| templates.name == :default }
            @case_templates.paths.each do |path|
              case_info = @case_templates.info(path)

              # Use the app's layout, if available.
              #
              if app_templates.layouts.include?(case_info[:page].info(:layout))
                case_info[:layout] = app_templates.layouts[case_info[:page].info(:layout)]
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

  let :reflected_app_def do
    Proc.new {}
  end

  let :controllers do
    Pakyow.apps.first.controllers.each.reject { |controller|
      controller == Test::Controllers::Authenticity
    }
  end
end
