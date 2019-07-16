# frozen_string_literal: true

require "pakyow/support/extension"

module Pakyow
  module Data
    module Config
      extend Support::Extension

      apply_extension do
        configurable :data do
          configurable :subscriptions do
            setting :adapter_settings, {}
            setting :version

            defaults :production do
              setting :adapter_settings do
                { key_prefix: [Pakyow.config.redis.key_prefix, config.name].join("/") }
              end
            end
          end
        end
      end
    end
  end
end
