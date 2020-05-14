# frozen_string_literal: true

require_relative "base"

module Pakyow
  module Runnable
    class Container
      module Strategies
        # @api private
        class Threaded < Base
          def initialize(*)
            super

            @failed_threads = []
          end

          def finish
            Thread.current.exit
          end

          private def stop(_signal)
            @services.each do |service|
              service.reference.kill
            end
          end

          private def invoke_service(service)
            Thread.new do
              run_service(service)
            end
          end

          private def service_failed!(service)
            @lock.synchronize do
              @failed_threads << service.reference
            end
          end

          private def wait_for_service(service)
            Thread.new do
              service.reference.join

              if service.status.unknown?
                if @failed_threads.include?(service.reference)
                  service.failed!
                else
                  service.success!
                end
              end

              @queue.push([:exit, service])
            end
          end
        end
      end
    end
  end
end
