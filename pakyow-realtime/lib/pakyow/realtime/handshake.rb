module Pakyow
  module Realtime
    # Handles the handshake for establishing a WebSocket connection.
    #
    class Handshake
      DELIMINATOR = "\r\n"
      HTTP_HEADER_REGEXP = /^HTTP_(.*)/

      attr_reader :server, :env, :io

      def initialize(env)
        @env = env
      end

      def perform
        @server = WebSocket::Handshake::Server.new
        @server << handshake_data_from_env(@env)
      end
      
      def finalize(io)
        return unless @server.valid?
        @io = io
        @io.write(server.to_s)
      end

      def valid?
        @server && @server.valid?
      end

      private

      def handshake_data_from_env(env)
        data = ["#{env['REQUEST_METHOD']} #{env['REQUEST_URI']} #{env['SERVER_PROTOCOL']}"]

        env.inject(data) do |acc, env_part|
          key, value = env_part

          if match = key.match(HTTP_HEADER_REGEXP)
            acc << "#{rack_env_key_to_http_header_name(match[1])}: #{value}"
          end

          acc
        end

        data.join(DELIMINATOR) << DELIMINATOR << DELIMINATOR
      end

      def rack_env_key_to_http_header_name(key)
        key.downcase.split('_').map(&:capitalize).join('-')
      end
    end
  end
end
