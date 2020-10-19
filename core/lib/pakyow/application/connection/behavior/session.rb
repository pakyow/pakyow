# frozen_string_literal: true

require "pakyow/support/extension"

module Pakyow
  class Application
    class Connection
      module Behavior
        module Session
          extend Support::Extension

          def session
            unless defined?(@session)
              @session = build_session
            end

            @session
          end

          private

          def build_session
            if @app.config.session.enabled
              @app.session_object.new(self, @app.session_options)
            end
          end
        end
      end
    end
  end
end
