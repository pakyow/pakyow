# frozen_string_literal: true

require "async/http/server"

module Pakyow
  class Server < Async::HTTP::Server
    class << self
      def run(context, endpoint:, protocol:, scheme:)
        new(context, endpoint: endpoint, protocol: protocol, scheme: scheme).run
      end
    end

    def initialize(context, endpoint:, protocol:, scheme:)
      super(context, endpoint, protocol: protocol, scheme: scheme)

      @wrappers = []
    end

    def run
      @endpoint.bind do |wrapper|
        @wrappers << wrapper

        wrapper.listen(Socket::SOMAXCONN)
        wrapper.accept_each(&method(:accept))
      rescue Async::Wrapper::Cancelled
        # the endpoint was closed
      end

      self
    end

    def shutdown
      @wrappers.each(&:close)
    end
  end
end
