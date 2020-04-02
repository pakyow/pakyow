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
      end

      # Dispatches the connection to an application.
      #
      def dispatch(connection)
        apps.each do |app|
          if connection.path.start_with?(app.mount_path)
            app.call(connection)
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
