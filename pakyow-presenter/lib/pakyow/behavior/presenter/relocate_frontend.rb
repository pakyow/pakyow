# frozen_string_literal: true

require "pakyow/support/extension"

module Pakyow
  module Behavior
    module Presenter
      # Extends the `create:app` command to relocate the default application's frontend when
      # converting the project to support multiple apps.
      #
      module RelocateFrontend
        extend Support::Extension

        apply_extension do
          after "load.commands" do
            command(:create, :application).class_eval do
              action :relocate_default_application_frontend, after: :relocate_default_application do
                next if default_app.nil? || Pakyow.apps.count > 1 || !default_app.class.includes_framework?(:presenter)

                if default_application_frontend_path.exist?
                  verify_path_within_root!(default_application_frontend_path)
                  FileUtils.mkdir_p(default_multiapp_application_frontend_path)
                  relocate(default_application_frontend_path, default_multiapp_application_frontend_path)
                  FileUtils.rm_r(default_application_frontend_path)
                end
              end

              private def default_application_frontend_path
                Pathname.new(File.expand_path(default_app.config.presenter.path))
              end

              private def default_multiapp_application_frontend_path
                default_multiapp_application_path.join(default_application_frontend_path.relative_path_from(root_path))
              end
            end
          end
        end
      end
    end
  end
end
