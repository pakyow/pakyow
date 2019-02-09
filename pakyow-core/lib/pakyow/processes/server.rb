# frozen_string_literal: true

require "async/http/server"

require "pakyow/support/extension"

module Pakyow
  module Processes
    class Server
      class << self
        def running_text(scheme:, host:, port:)
          text = String.new("Pakyow › #{Pakyow.env.capitalize}")
          text << " › #{scheme}://#{host}:#{port}"

          Support::CLI.style.blue.bold(
            text
          ) + Support::CLI.style.italic("\nUse Ctrl-C to shut down the environment.")
        end
      end

      def initialize(endpoint:, protocol:, scheme:)
        @endpoint, @protocol, @scheme = endpoint, protocol, scheme
      end

      def run
        Async::HTTP::Server.new(
          Pakyow.boot, @endpoint, @protocol, @scheme
        ).run
      end
    end
  end
end
