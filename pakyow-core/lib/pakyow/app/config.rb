# frozen_string_literal: true

require "pakyow/support/extension"
require "pakyow/support/path_version"

module Pakyow
  class App
    module Config
      extend Support::Extension

      apply_extension do
        setting :name, :pakyow
        setting :version

        setting :root do
          Pakyow.config.root
        end

        setting :src do
          File.join(config.root, "backend")
        end

        setting :lib do
          File.join(config.src, "lib")
        end

        configurable :tasks do
          setting :prelaunch, []
        end

        configurable :session do
          setting :enabled, true
          setting :object, :cookie

          configurable :cookie do
            setting :name do
              "#{config.name}.session"
            end

            setting :domain do
              Pakyow.config.cookies.domain
            end

            setting :path do
              Pakyow.config.cookies.path
            end

            setting :max_age do
              Pakyow.config.cookies.max_age
            end

            setting :expires do
              Pakyow.config.cookies.expires
            end

            setting :secure do
              Pakyow.config.cookies.secure
            end

            setting :http_only do
              true
            end

            setting :same_site do
              Pakyow.config.cookies.same_site
            end
          end
        end
      end
    end
  end
end
