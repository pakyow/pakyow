# frozen_string_literal: true

require "pakyow/support/extension"
require "pakyow/support/inflector"

module Pakyow
  class Application
    module Behavior
      module Sessions
        extend Support::Extension

        apply_extension do
          class_state :session_object, inheritable: true
          class_state :session_options, inheritable: true

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

          after "configure" do
            if config.session.enabled
              require "pakyow/application/connection/session/#{config.session.object}"

              @session_object = Pakyow::Application::Connection::Session.const_get(
                Support.inflector.classify(config.session.object)
              )

              @session_options = if config.session.respond_to?(config.session.object)
                config.session.public_send(config.session.object)
              else
                {}
              end
            end
          rescue LoadError => error
            # TODO: Improve this with a specific "session object missing" error.
            #
            raise error
          end
        end

        def session_object
          # TODO: Deprecate.
          self.class.session_object
        end

        def session_options
          # TODO: Deprecate.
          self.class.session_options
        end
      end
    end
  end
end
