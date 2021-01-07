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

          private def terminate_service(service)
            service.reference.kill
          end
        end
      end
    end
  end
end
