# frozen_string_literal: true

require_relative "base"

module Pakyow
  module Runnable
    class Container
      module Strategies
        # @api private
        class Threaded < Base
          private def invoke_service(service)
            Thread.new do
              yield
            ensure
              if service.status.unknown?
                service.success!
              end

              @notifier.notify(:exit, service: service.id, status: service.status)
            end
          end

          private def stop_service(service, signal)
            case signal
            when :int
              Pakyow.async {
                service.stop
              }
            else
              service.reference.kill
            end
          end
        end
      end
    end
  end
end
