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

            def initialize(...)
              @fetched = false
              @logger = Logger.new(:extl, output: Pakyow.output, level: Pakyow.config.logger.level)

              super
            end

            def perform
              ensure_booted do
                Pakyow.apps.reject { |app|
                  app.rescued?
                }.select { |app|
                  app.class.includes_framework?(:assets) && app.config.assets.externals.fetch
                }.each do |app|
                  fetch!(app)

                  app.plugs.each do |plug|
                    fetch!(plug)
                  end
                end
              end
            end

            def shutdown
              return unless fetched?

              @logger.info "Update completed"

              Pakyow.restart
            end

            private def fetch!(context)
              context.config.assets.externals.scripts.each do |external_script|
                unless external_script.exist?
                  @logger.info "[#{context.config.name}] Updating external asset #{external_script.name_with_version}"

                  external_script.fetch!

                  @fetched = true
                end
              rescue => error
                Pakyow.houston(error)
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
