# frozen_string_literal: true

module Pakyow
  module Actions
    # Restarts the environment with a particular configuration.
    #
    class Restart
      def call(connection)
        if connection.path == "/pw-restart" && connection.method == :post && environment = connection.params[:environment]
          FileUtils.mkdir_p "./tmp"
          File.open("./tmp/restart.txt", "w+") do |file|
            file.write environment
          end

          connection.halt
        end
      end
    end
  end
end
