# frozen_string_literal: true

require "async/reactor"
require "async/io/shared_endpoint"
require "async/http/endpoint"

require "pakyow/support/extension"

require_relative "../errors"
require_relative "../server"
require_relative "../runnable/container"

require_relative "running/ensure_booted"

module Pakyow
  module Behavior
    module Running
      extend Support::Extension

      apply_extension do
        class_state :__running_container, default: nil, reader: false

        definable :container, Runnable::Container

        container :supervisor do
          on :restart do |env:|
            options[:env] = env if env
          end

          service :environment do
            include EnsureBooted

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
              ensure_booted do
                GC.start

                Pakyow.container(:environment).run(parent: self, **options) do |instance|
                  @container = instance
                end
              end
            end

            def shutdown
              @container&.stop
            end
          end
        end

        container :environment do
          service :server do
            include EnsureBooted

            def count
              handling do
                # Load first so that the count is correctly configured.
                #
                Pakyow.load(env: options[:env])
              end

              options[:config].server.count
            end

            class << self
              def prerun(options)
                Pakyow.container(:server).services.each do |service|
                  service.prerun(options)
                end
              end

              def postrun(options)
                Pakyow.container(:server).services.each do |service|
                  service.postrun(options)
                end
              end
            end

            def perform
              ensure_booted do
                GC.start

                options[:strategy] = :threaded
                Pakyow.container(:server).run(parent: self, **options) do |instance|
                  @container = instance
                end
              end
            end

            def shutdown
              @container&.stop
            end
          end
        end

        container :server do
          service :endpoint do
            include EnsureBooted

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

                if Pakyow.config.polite
                  Pakyow.logger << running_text(
                    env: options[:env],
                    scheme: options[:config].server.scheme,
                    host: options[:config].server.host,
                    port: options[:config].server.port
                  )
                end
              end

              def postrun(options)
                options[:endpoint].close
              end

              private def running_text(env:, scheme:, host:, port:)
                text = +"Pakyow › #{env.to_s.capitalize}"
                text << " › #{scheme}://#{host}:#{port}"

                if $stdout.tty?
                  Support::CLI.style.blue.bold(
                    text
                  ) + Support::CLI.style.italic("\nUse Ctrl-C to shut down the environment.")
                else
                  text
                end
              end
            end

            def initialize(*, **)
              super

              @server = nil
            end

            def logger
              nil
            end

            def perform
              ensure_booted do
                @server = Server.run(
                  Pakyow,
                  endpoint: options[:endpoint],
                  protocol: options[:protocol],
                  scheme: options[:config].server.scheme
                )
              end
            end

            def shutdown
              @server&.shutdown

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
                env: env
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

            if config.polite
              Pakyow.logger << "Goodbye"
            end

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
