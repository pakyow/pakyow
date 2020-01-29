# frozen_string_literal: true

require "pakyow/support"
require "pakyow/routing"
require "pakyow/presenter"

require "pakyow/realtime/framework"

require "pakyow/application/actions/realtime/upgrader"

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
  end
end
