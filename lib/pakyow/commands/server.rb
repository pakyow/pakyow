require "pakyow/version"
require "pakyow/core/logger/colorizer"

module Pakyow
  module Commands
    class Server
      RACK_ENV = "RACK_ENV".freeze

      def initialize(env: nil, port: nil, host: nil, server: nil)
        @env    = env.to_s
        @port   = port
        @host   = host
        @server = server
      end

      def run
        puts Logger::Colorizer.colorize(
          File.read(
            File.expand_path("../output/splash.txt", __FILE__)
          ).gsub!("{v}", "v#{VERSION}"), :error)

        require "./config/environment"
        Pakyow.setup(env: @env).run(port: @port, host: @host, server: @server)
      end
    end
  end
end
