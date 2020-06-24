# frozen_string_literal: true

require "pakyow/support/deep_freeze"
require "pakyow/support/extension"

require_relative "error_handling"

module Pakyow
  module Behavior
    module Running
      module EnsureBooted
        extend Support::Extension

        using Support::DeepFreeze

        include_dependency ErrorHandling

        # Call from a service to ensure that the environment has booted. Yields when booted.
        #
        private def ensure_booted
          if Pakyow.booted?
            yield unless Pakyow.rescued?
          elsif !Pakyow.rescued?
            handling do
              Pakyow.boot(env: options[:env])

              yield

              Pakyow.deprecator.ignore do
                if Pakyow.config.freeze_on_boot
                  Pakyow.deep_freeze
                end
              end
            end
          end
        end
      end
    end
  end
end
