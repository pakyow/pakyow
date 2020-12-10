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

          private def stop_service(service, signal)
            ::Process.kill(signal, service.reference)
          rescue Errno::ESRCH
          end

          private def service_failed!(service)
            ::Process.exit(1)
          end

          private def invoke_service(service)
            reference = ::Process.fork do
              yield
            end

            watch_forks(service, reference)
          end

          private def watch_forks(service, service_reference)
            @lock.synchronize do
              @forked_services[service_reference] = service
            end

            unless @watching
              @watching = true

              Thread.new do
                while (reference, status = ::Process.wait2(-1))
                  next unless service = @lock.synchronize {
                    @forked_services.delete(reference)
                  }

                  case status
                  when 0
                    service.success!
                  else
                    service.failed!
                  end

                  @notifier.notify(:exit, service: service.object_id)
                end
              rescue Errno::ECHILD
              ensure
                @watching = false
              end
            end

            service_reference
          end
        end
      end
    end
  end
end
