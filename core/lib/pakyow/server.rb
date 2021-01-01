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
      super(context, endpoint, protocol, scheme)

      @server = nil
    end

    def run
      @endpoint.bind do |server|
        @server = server
        @server.listen(Socket::SOMAXCONN)
        @server.accept_each(&method(:accept))
      rescue Async::Wrapper::Cancelled
        # the endpoint was closed
      end

      self
    end

    def shutdown
      @server&.io&.close
    end
  end
end
