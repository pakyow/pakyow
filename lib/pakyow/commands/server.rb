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
        v = 'v' + Pakyow::VERSION

        msg = '                 __                      ' + "\n"\
              '    ____  ____ _/ /____  ______ _      __' + "\n"\
              '   / __ \/ __ `/ //_/ / / / __ \ | /| / /' + "\n"\
              '  / /_/ / /_/ / ,< / /_/ / /_/ / |/ |/ / ' + "\n"\
              ' / .___/\__,_/_/|_|\__, /\____/|__/|__/  ' + v + "\n"\
              '/_/               /____/                 ' + "\n"

        puts Pakyow::Logger::COLOR_SEQ % (30 + Pakyow::Logger::COLOR_TABLE.index(:red)) + msg + Pakyow::Logger::RESET_SEQ

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
