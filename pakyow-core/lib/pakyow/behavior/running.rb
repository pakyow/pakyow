# frozen_string_literal: true

require "async/reactor"
require "async/io/shared_endpoint"
require "async/http/endpoint"

require "pakyow/support/extension"

require "pakyow/errors"
require "pakyow/process"
require "pakyow/process_manager"
require "pakyow/processes/proxy"
require "pakyow/processes/server"

module Pakyow
  module Behavior
    module Running
      extend Support::Extension

      apply_extension do
        class_state :processes, default: []
        class_state :__running, default: false, reader: false

        on "run" do
          endpoint = Async::HTTP::Endpoint.parse(
            "http://#{config.server.host}:#{config.server.port}"
          )

          @bound_endpoint = Async::Reactor.run {
            Async::IO::SharedEndpoint.bound(endpoint)
          }.wait

          process :server, count: config.server.count do
            Processes::Server.new(
              protocol: endpoint.protocol,
              scheme: endpoint.scheme,
              endpoint: @bound_endpoint
            ).run
          end

          unless ENV.key?("PW_RESPAWN")
            Pakyow.logger << Processes::Server.running_text(
              scheme: "http", host: config.server.host, port: config.server.port
            )
          end
        end
      end

      class_methods do
        def process(name, count: 1, restartable: true, &block)
          @processes << Process.new(
            name: name,
            count: count,
            restartable: restartable,
            &block
          )
        end

        # Runs the environment by booting and starting all registered processes.
        #
        # @param env [Symbol] the environment to prepare for
        #
        def run(env: nil)
          unless running?
            boot(env: env)

            Async::Reactor.run do |reactor|
              @__reactor = reactor

              handle_at_exit
              call_hooks :before, :run
              @__process_thread = start_processes
              @__running = true
            end

            if defined?(@__process_thread)
              @__process_thread.join
            end

            call_hooks :after, :run
          end

          self
        rescue ApplicationError => error
          error.context.rescue!(error); retry
        rescue SignalException, Interrupt
          exit
        rescue => error
          @error = error
          logger.houston(error)
          if config.exit_on_boot_failure
            exit(false)
          end
        end

        # Returns true if the environment is running.
        #
        def running?
          @__running == true
        end

        def shutdown
          if running?
            performing :shutdown do
              # Stop the async reactor.
              #
              @__reactor.stop

              # Close the bound endpoint so we can respawn on the same port.
              #
              if defined?(@bound_endpoint)
                @bound_endpoint.close
              end

              # Finally, stop the process manager to invoke the respawn.
              #
              if defined?(@process_manager)
                @process_manager.stop
              end
            end

            @__running = false
          end

          self
        end

        def restart(environment = nil)
          unless environment.nil? || environment.empty?
            environment = environment.strip.to_sym
            unless environment == Pakyow.env
              Pakyow.setup(env: environment)
            end
          end

          boot; @process_manager.restart
        end

        def async(&block)
          @__reactor.async(&block)
        end

        private def start_processes
          @process_manager = ProcessManager.new

          Thread.new do
            @processes.each do |process|
              @process_manager.add(process)
            end

            @process_manager.wait
          end
        end

        private def handle_at_exit
          root_pid = ::Process.pid

          at_exit do
            if ::Process.pid == root_pid
              if $stdout.isatty
                # Don't let ^C mess up our output.
                #
                puts
              end

              shutdown

              Pakyow.logger << "Goodbye"
            else
              @apps.each do |app|
                app.shutdown
              rescue ApplicationError => error
                app.rescue!(error)
              end
            end
          end
        end
      end
    end
  end
end
