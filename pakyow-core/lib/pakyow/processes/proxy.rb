# frozen_string_literal: true

require "pakyow/support/deep_freeze"
require "pakyow/support/deprecatable"
require "pakyow/support/system"

module Pakyow
  module Processes
    # @deprecated No longer used (will be removed in v2.0).
    #
    class Proxy
      extend Support::Deprecatable
      deprecate

      using Support::DeepFreeze

      class << self
        extend Support::Deprecatable

        def find_local_port
          Support::System.available_port
        end

        deprecate :find_local_port, solution: "use `Pakyow::Support::System::available_port'"
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

          Pakyow.deprecator.ignore do
            if Pakyow.config.freeze_on_boot
              Pakyow.deep_freeze
            end
          end
        end
      end

      # @deprecated No longer used (will be removed in v2.0).
      #
      class Server
        extend Support::Deprecatable
        deprecate

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
