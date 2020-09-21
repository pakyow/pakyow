# frozen_string_literal: true

module Pakyow
  module Actions
    # Restarts the environment with a particular configuration.
    #
    class Restart
      def call(connection)
        if connection.path == "/pw-restart" && connection.method == :post && (environment = connection.params[:environment])
          Pakyow.restart(env: environment)

          connection.halt
        end
      end
    end
  end
end
