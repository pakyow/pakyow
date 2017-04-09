require "pakyow/version"
require "pakyow/logger/colorizer"

module Pakyow
  # @api private
  module Commands
    # @api private
    class Server
      def initialize(env: nil, port: nil, host: nil, server: nil)
        @env    = env
        @port   = port
        @host   = host
        @server = server
      end

      def run
        puts Logger::Colorizer.colorize(
          File.read(
            File.expand_path("../output/splash.txt", __FILE__)
          ).gsub!("{v}", "v#{VERSION}"), :error
        )

        require "./config/environment"
        Pakyow.setup(env: @env).run(port: @port, host: @host, server: @server)
      end
    end
  end
end
