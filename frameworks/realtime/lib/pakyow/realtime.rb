# frozen_string_literal: true

require "pakyow/routing"
require "pakyow/presenter"

require_relative "realtime/framework"
require_relative "realtime/server"

module Pakyow
  configurable :realtime do
    setting :server, true

    setting :adapter, :memory
    setting :adapter_settings, {}

    defaults :production do
      setting :adapter, :redis
      setting :adapter_settings do
        Pakyow.config.redis.to_h
      end
    end

    configurable :timeouts do
      # Give sockets 60 seconds to connect before cleaning up their state.
      #
      setting :initial, 60

      # When a socket disconnects, keep state around for 24 hours before
      # cleaning up. This improves the user experience in cases such as
      # when a browser window is left open on a sleeping computer.
      #
      setting :disconnect, 24 * 60 * 60
    end
  end

  container(:server).service(:websockets) do
    def initialize(...)
      super

      @server = Realtime::Server.new(
        Pakyow.config.realtime.adapter,
        Pakyow.config.realtime.adapter_settings.to_h,
        Pakyow.config.realtime.timeouts
      )
    end

    def perform
      @server.run
    end

    def shutdown
      @server&.shutdown
    end
  end
end
