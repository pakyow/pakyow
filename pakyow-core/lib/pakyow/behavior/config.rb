# frozen_string_literal: true

require "pakyow/support/extension"

module Pakyow
  module Behavior
    module Config
      extend Support::Extension

      apply_extension do
        setting :name, "pakyow"

        setting :root do
          Pakyow.config.root
        end

        setting :src do
          File.join(config.root, "backend")
        end

        setting :lib do
          File.join(config.src, "lib")
        end

        configurable :tasks do
          setting :prelaunch, []
        end
      end
    end
  end
end
