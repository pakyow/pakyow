# frozen_string_literal: true

require "async/reactor"
require "async/io/shared_endpoint"
require "async/http/endpoint"

require "pakyow/support/deep_freeze"
require "pakyow/support/deprecatable"
require "pakyow/support/extension"

require_relative "../errors"
require_relative "../server"
require_relative "../runnable/container"

require_relative "running/error_handling"

module Pakyow
  module Behavior
    module Running
      extend Support::Extension

      apply_extension do
        class_state :__running_container, default: nil, reader: false

        definable :container, Runnable::Container

        container :supervisor do
          # Boots and deep freezes the environment, then runs the environment container.
          #
          service :environment do
            include ErrorHandling

            using Support::DeepFreeze

            class << self
              def prerun(options)
                Pakyow.container(:environment).services.each do |service|
                  service.prerun(options)
                end
              end

              def postrun(options)
                Pakyow.container(:environment).services.each do |service|
                  service.postrun(options)
                end
              end
            end

            def perform
              handling do
                Pakyow.boot(env: options[:env])

                Pakyow.deprecator.ignore do
                  if Pakyow.config.freeze_on_boot
                    Pakyow.deep_freeze
                  end
                end

                GC.start
              end

              Pakyow.container(:environment).run(parent: self, **options)
            end
          end
        end

        container :environment do
          # Boots the environment (if necessary), then runs the server.
          #
          service :server do
            include ErrorHandling

            using Support::DeepFreeze

            class << self
              def prerun(options)
                endpoint = Async::HTTP::Endpoint.parse(
                  "#{options[:config].server.scheme}://#{options[:config].server.host}:#{options[:config].server.port}"
                )

                bound_endpoint = Async::Reactor.run {
                  Async::IO::SharedEndpoint.bound(endpoint)
                }.wait

                options[:endpoint] = bound_endpoint
                options[:protocol] = endpoint.protocol

                Pakyow.logger << running_text(
                  env: options[:env],
                  scheme: options[:config].server.scheme,
                  host: options[:config].server.host,
                  port: options[:config].server.port
                )
              end

              def postrun(options)
                options[:endpoint].close
              end

              private def running_text(env:, scheme:, host:, port:)
                text = String.new("Pakyow › #{env.to_s.capitalize}")
                text << " › #{scheme}://#{host}:#{port}"

                Support::CLI.style.blue.bold(
                  text
                ) + Support::CLI.style.italic("\nUse Ctrl-C to shut down the environment.")
              end
            end

            def count
              options[:config].server.count
            end

            def perform
              handling do
                unless Pakyow.booted?
                  Pakyow.boot(env: options[:env])

                  Pakyow.deprecator.ignore do
                    if Pakyow.config.freeze_on_boot
                      Pakyow.deep_freeze
                    end
                  end
                end
              end

              Server.run(
                Pakyow,
                endpoint: options[:endpoint],
                protocol: options[:protocol],
                scheme: options[:config].server.scheme
              )
            end

            def shutdown
              Pakyow.apps.each do |app|
                app.shutdown
              rescue ApplicationError => error
                app.rescue!(error)
              end
            end
          end
        end
      end

      class_methods do
        extend Support::Deprecatable

        def process(name, restartable: true, &block)
          container(:environment).service(name, restartable: restartable) do
            def perform
              block.call
            end
          end
        end

        deprecate :process, solution: "define services directly on `Pakyow.container(:environment)'"

        # Runs the environment by defining the shared endpoint and running the top-level container.
        #
        # @param env [Symbol] the environment to run
        # @param formation [Hash] the formation to run
        # @param strategy [Symbol] the strategy to run
        #
        def run(env: nil, formation: nil, strategy: :hybrid)
          unless running?
            formation ||= config.runnable.formation
            validate_formation!(formation)

            performing :run do
              top_level_container(formation).run(
                strategy: strategy,
                formation: formation,
                config: config.runnable,
                env: env,
              ) do |container|
                @__running_container = container
                yield container if block_given?
              end
            end

            shutdown

            if $stdout.isatty
              # Don't let ^C mess up our output.
              #
              puts
            end

            Pakyow.logger << "Goodbye"

            ::Process.exit(@__running_container.success?)
          end

          self
        end

        # Returns true if the environment is running.
        #
        def running?
          !@__running_container.nil? && @__running_container.running?
        end

        # Shutdown the environment.
        #
        def shutdown
          if running?
            performing :shutdown do
              # Make sure the container is stopped.
              #
              @__running_container.stop
            end
          end

          self
        end

        # Restart the environment.
        #
        def restart(env: Pakyow.env)
          if running?
            @__running_container.restart(env: env)
          end
        end

        private def validate_formation!(formation)
          unless top_level_container(formation)
            raise FormationError.new_with_message(:missing, formation: formation, container: formation.container)
          end
        end

        private def top_level_container(formation)
          if formation.nil? || formation.service?(:all)
            container(:supervisor)
          else
            container(formation.container)
          end
        end
      end
    end
  end
end
