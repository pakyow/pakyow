# frozen_string_literal: true

require "pakyow/support/extension"

require "pakyow/behavior/running/ensure_booted"

module Pakyow
  module Behavior
    module Assets
      module Externals
        extend Support::Extension

        apply_extension do
          container(:environment).service(:externals, restartable: false, limit: 1) do
            include Running::EnsureBooted

            def initialize(*)
              @fetched = false

              super
            end

            def perform
              ensure_booted do
                Pakyow.apps.each do |app|
                  next unless app.class.includes_framework?(:assets)
                  next unless app.config.assets.externals.fetch

                  fetch!(app)

                  app.plugs.each do |plug|
                    fetch!(plug)
                  end
                end
              end
            end

            def shutdown
              Pakyow.restart if fetched?
            end

            private def fetch!(context)
              context.config.assets.externals.scripts.each do |external_script|
                unless external_script.exist?
                  external_script.fetch!

                  @fetched = true
                end
              end
            end

            private def fetched?
              @fetched == true
            end
          end
        end
      end
    end
  end
end
