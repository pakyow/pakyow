module Pakyow
  module Commands
    class Server
      attr_reader :port

      def initialize(environment: ENV['RACK_ENV'] || :development, port: 3000)
        ENV['RACK_ENV'] = environment.to_s
        @port = port
      end

      def run
        load_app
        Pakyow::Config.server.port = port
        Pakyow::App.run(ENV['RACK_ENV'])
      end

      private

      def load_app
        $LOAD_PATH.unshift(Dir.pwd)
        require 'app/setup'
      end
    end
  end
end
