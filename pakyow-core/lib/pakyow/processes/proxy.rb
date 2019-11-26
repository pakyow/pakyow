# frozen_string_literal: true

require "pakyow/support/deep_freeze"

module Pakyow
  module Processes
    class Proxy
      using Support::DeepFreeze

      class << self
        def find_local_port
          server = TCPServer.new("127.0.0.1", 0)
          port = server.addr[1]
          server.close
          port
        end
      end

      def initialize(host:, port:, proxy_port:)
        @host, @port, @proxy_port = host, port, proxy_port
      end

      def run
        endpoint = Async::HTTP::Endpoint.parse(
          "http://#{@host}:#{@port}"
        )

        server = Server.new(
          host: @host, port: @proxy_port, forwarded: "#{@host}:#{@port}"
        )

        Async::Reactor.run do
          Async::HTTP::Server.new(server, endpoint).run

          if !ENV.key?("PW_RESPAWN")
            Pakyow.logger << Pakyow::Processes::Server.running_text(
              scheme: "http", host: @host, port: @port
            )
          end

          if Pakyow.config.freeze_on_boot
            Pakyow.deep_freeze
          else
            Pakyow.deprecated "config.freeze_on_boot", "do not change this setting"
          end
        end
      end

      class Server
        def initialize(port:, host:, forwarded:)
          @port, @host, @forwarded = port, host, forwarded
          @destination = "#{@host}:#{@port}"
          @client = Async::HTTP::Client.new(
            Async::HTTP::Endpoint.parse(
              File.join("http://#{@destination}")
            )
          )
        end

        def call(request, total_waits = 0)
          @client.call(request)
        rescue
          if total_waits == 30
            Async::HTTP::Protocol::Response.new(
              nil, 404, [], Async::HTTP::Body::Buffered.wrap(
                StringIO.new("app did not respond")
              )
            )
          else
            Async::Task.current.sleep 0.5
            call(request, total_waits + 1)
          end
        end
      end
    end
  end
end
