# frozen_string_literal: true

module Pakyow
  module Behavior
    module Dispatching
      extend Support::Extension

      apply_extension do
        # Add the dispatch action. Doing it here guarantees that user actions load before dispatch.
        #
        after :setup do
          action :dispatch
        end

        events :dispatch
      end

      # Dispatches the connection to an application.
      #
      def dispatch(connection)
        performing :dispatch, connection: connection do
          apps.each do |app|
            app.call(connection) if app.accept?(connection)
          end
        end

        unless connection.halted? || connection.streaming?
          connection.status = 404
          connection.body = "404 Not Found"
        end
      rescue StandardError => error
        houston(error)
        connection.error = error
        connection.status = 500
        connection.body = "500 Server Error"
      end
    end
  end
end
