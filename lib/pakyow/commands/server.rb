module Pakyow
  module Commands
    class Server
      attr_reader :environment, :port

      def initialize(environment: :development, port:)
        @environment = environment
        @port = port
      end

      def run
        load_app
        Pakyow::Config.server.port = port
        Pakyow::App.run(environment)
      end

      private

      def load_app
        $LOAD_PATH.unshift(Dir.pwd)
        require 'app/setup'
      end
    end
  end
end
