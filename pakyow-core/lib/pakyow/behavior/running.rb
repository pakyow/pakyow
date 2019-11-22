# frozen_string_literal: true

require "async/reactor"
require "async/io/shared_endpoint"
require "async/http/endpoint"

require "pakyow/support/extension"

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

        on "run" do
          if config.server.proxy
            # Find a port to run the environment on, start the proxy on the configured port.
            #
            @proxy_port = port = if ENV.key?("PW_PROXY_PORT")
              ENV["PW_PROXY_PORT"].to_i
            else
              Processes::Proxy.find_local_port
            end

            process :proxy, restartable: false do
              Processes::Proxy.new(
                host: config.server.host,
                port: config.server.port,
                proxy_port: port
              ).run
            end
          else
            # Run the environment on the configured port.
            #
            port = config.server.port
          end

          endpoint = Async::HTTP::Endpoint.parse(
            "http://#{config.server.host}:#{port}"
          )

          @bound_endpoint = Async::Reactor.run {
            Async::IO::SharedEndpoint.bound(endpoint)
          }.wait

          process :server, count: config.server.count do
            Pakyow.config.server.port = port

            Processes::Server.new(
              protocol: endpoint.protocol,
              scheme: endpoint.scheme,
              endpoint: @bound_endpoint
            ).run
          end

          unless config.server.proxy || ENV.key?("PW_RESPAWN")
            Pakyow.logger << Processes::Server.running_text(
              scheme: "http", host: config.server.host, port: port
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

        def run
          Async::Reactor.run do |reactor|
            @__reactor = reactor

            handle_at_exit
            call_hooks :before, :run
            @__process_thread = start_processes
          end

          if defined?(@__process_thread)
            @__process_thread.join
          end

          call_hooks :after, :run
        rescue SignalException, Interrupt
          exit
        end

        def shutdown
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
        end

        def restart(environment = nil)
          unless environment.nil? || environment.empty?
            environment = environment.strip.to_sym
            unless environment == Pakyow.env
              Pakyow.setup(env: environment)
            end
          end

          @process_manager.restart
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

              Pakyow.logger << "Goodbye"

              shutdown
            else
              @apps.select { |app|
                app.respond_to?(:shutdown)
              }.each(&:shutdown)
            end
          end
        end
      end
    end
  end
end
