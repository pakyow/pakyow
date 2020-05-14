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
    end
  end
end
