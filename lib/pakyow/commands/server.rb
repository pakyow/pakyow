require "pakyow/version"

module Pakyow
  module Commands
    class Server
      RACK_ENV = "RACK_ENV".freeze

      def initialize(environment: ENV[RACK_ENV] || Config.app.default_environment, port: Config.server.port)
        ENV[RACK_ENV] = environment.to_s
        @port = port
      end

      def run
        require "./app/setup"
        Config.server.port = @port
        v = "v" + VERSION

        msg = '                 __                      ' + "\n" \
              '    ____  ____ _/ /____  ______ _      __' + "\n" \
              '   / __ \/ __ `/ //_/ / / / __ \ | /| / /' + "\n" \
              '  / /_/ / /_/ / ,< / /_/ / /_/ / |/ |/ / ' + "\n" \
              ' / .___/\__,_/_/|_|\__, /\____/|__/|__/  ' + v + "\n" \
              '/_/               /____/                 ' + "\n"
        puts Logger::Colorizer.colorize(msg, :error)

        App.run(ENV[RACK_ENV])
      end
    end
  end
end
