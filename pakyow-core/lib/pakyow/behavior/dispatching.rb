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
        finished = false

        performing :dispatch, connection: connection do
          catch :halt do
            apps.find do |app|
              app.mount_path && app.accept?(connection)
            end&.call(connection)

            finished = true
          end
        end

        throw :halt unless finished
      end
    end
  end
end
