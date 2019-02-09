# frozen_string_literal: true

require "pakyow/support/extension"

module Pakyow
  class App
    class Connection
      module Behavior
        module Session
          extend Support::Extension

          def session
            unless instance_variable_defined?(:@session)
              @session = build_session
            end

            @session
          end

          private

          def build_session
            if @app.config.session.enabled
              @app.session_object.new(self, @app.session_options)
            else
              nil
            end
          end
        end
      end
    end
  end
end
