# frozen_string_literal: true

require_relative "base"

module Pakyow
  module Runnable
    class Container
      module Strategies
        # @api private
        class Forked < Base
          def finish
            ::Process.exit(success?)
          end

          private def stop(signal)
            @services.each do |service|
              ::Process.kill(signal, service.reference)
            rescue Errno::ESRCH
            end
          end

          private def service_failed!(service)
            ::Process.exit(1)
          end

          private def wait_for_service(service)
            Thread.new do
              case ::Process.wait2(service.reference)[1].to_i
              when 0
                service.success!
              else
                service.failed!
              end

              @queue.push([:exit, service])
            rescue Errno::ECHILD
              @queue.push([:exit, service])
            end
          end

          private def invoke_service(service)
            ::Process.fork do
              run_service(service)
            end
          end
        end
      end
    end
  end
end
