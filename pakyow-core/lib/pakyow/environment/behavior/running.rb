# frozen_string_literal: true

require "async/reactor"
require "async/io/shared_endpoint"
require "async/http/endpoint"

require "pakyow/support/extension"

require "pakyow/process_manager"
require "pakyow/processes/proxy"
require "pakyow/processes/server"

module Pakyow
  module Environment
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
              port = Processes::Proxy.find_local_port
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
                scheme: endpoint.scheme, host: config.server.host, port: port
              )
            end
          end
        end

        class_methods do
          def process(name, count: 1, restartable: true, &block)
            @processes << {
              name: name,
              block: block,
              count: count,
              restartable: restartable
            }
          end

          def run
            performing :run do
              @process_manager = @processes.each_with_object(ProcessManager.new) { |process, manager|
                manager.add(process)
              }

              root_pid = Process.pid

              at_exit do
                if Process.pid == root_pid
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
              # Replace the master process with a copy of itself.
              #
              exec "PW_RESPAWN=true #{$0} #{ARGV.join(" ")}"
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

          def restart
            @process_manager.restart
          end
        end
      end
    end
  end
end
