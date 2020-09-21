# frozen_string_literal: true

require "async/http/server"

require "pakyow/support/deep_freeze"
require "pakyow/support/deprecatable"
require "pakyow/support/extension"

module Pakyow
  module Processes
    class Server
      extend Support::Deprecatable
      deprecate

      using Support::DeepFreeze

      class << self
        def running_text(scheme:, host:, port:)
          text = +"Pakyow › #{Pakyow.env.capitalize}"
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
        Async::Reactor.run do
          Pakyow.deprecator.ignore do
            if Pakyow.config.freeze_on_boot
              Pakyow.deep_freeze
            end
          end

          Async::HTTP::Server.new(Pakyow, @endpoint, @protocol, @scheme).run
        end
      end
    end
  end
end
