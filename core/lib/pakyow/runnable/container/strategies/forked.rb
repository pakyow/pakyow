# frozen_string_literal: true

require_relative "base"

module Pakyow
  module Runnable
    class Container
      module Strategies
        # @api private
        class Forked < Base
          def initialize(*)
            super

            @lock = Mutex.new
            @watching = false
            @forked_services = {}
          end

          private def stop_service(service)
            ::Process.kill(:INT, service.reference)
          rescue Errno::ESRCH
          end

          private def terminate_service(service)
            ::Process.kill(:TERM, service.reference)
          rescue Errno::ESRCH
          end

          private def quit_service(service)
            ::Process.kill(:KILL, service.reference)
          rescue Errno::ESRCH
          end

          private def service_finished(service)
            if service.status.unknown?
              service.status.success!
            end

            # This seems to resolve an issue where services aren't identified as exited fast enough
            # in `watch_forks`, so shutting down at the same time a service exits can cause the
            # service to appear failed when it in fact succeeeded.
            #
            await do
              @notifier.notify(:exit, service: service.id, status: service.status)
            end

            ::Process.exit(service.status.success?)
          end

          private def invoke_service(service)
            reference = ::Process.fork {
              begin
                Signal.trap(:INT) do
                  service.stop
                end

                Signal.trap(:TERM) do
                  raise Terminate
                end

                reset_fork_state

                yield
              rescue Terminate
                # fin
              end
            }

            watch_forks(service, reference)
          rescue Terminate
          end

          private def watch_forks(service, service_reference)
            @lock.synchronize do
              @forked_services[service_reference] = service
            end

            unless @watching
              @watching = true

              Thread.new do
                while (reference, status = ::Process.wait2(-1))
                  if (service = @lock.synchronize { @forked_services.delete(reference) })
                    case status.success?
                    when true
                      service.success!
                    when false
                      service.failed!
                    end

                    await do
                      @notifier.notify(:exit, service: service.id, status: service.status)
                    end
                  end
                end
              rescue Errno::ECHILD
              ensure
                @watching = false
              end
            end

            service_reference
          end

          private def reset_fork_state
            @watching = false
            @forked_services = {}
          end
        end
      end
    end
  end
end
