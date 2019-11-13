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
        unfreezable :process_manager

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

          bound_endpoint = Async::Reactor.run {
            Async::IO::SharedEndpoint.bound(endpoint)
          }.wait

          process :server, count: config.server.count do
            Pakyow.config.server.port = port

            Processes::Server.new(
              protocol: endpoint.protocol,
              scheme: endpoint.scheme,
              endpoint: bound_endpoint
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
          performing :run do
            @process_manager = @processes.each_with_object(ProcessManager.new) { |process, manager|
              manager.add(process)
            }

            root_pid = ::Process.pid

            at_exit do
              if ::Process.pid == root_pid
                shutdown
              else
                @apps.select { |app|
                  app.respond_to?(:shutdown)
                }.each(&:shutdown)
              end
            end
          end

          @process_manager.wait

          if @respawn
            respawn_command = "PW_RESPAWN=true PW_PROXY_PORT=#{@proxy_port} #{$0} #{ARGV.join(" ")}"

            if @respawn_environment
              respawn_command = respawn_command + " -e #{@respawn_environment}"
            end

            # Replace the master process with a copy of itself.
            #
            exec respawn_command
          end
        rescue SignalException
          exit
        end

        def shutdown
          if $stdout.isatty
            # Don't let ^C mess up our output.
            #
            puts
          end

          Pakyow.logger << "Goodbye"

          performing :shutdown do
            @process_manager.stop
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
      end
    end
  end
end
