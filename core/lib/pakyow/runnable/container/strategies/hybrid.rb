# frozen_string_literal: true

require_relative "base"
require_relative "forked"
require_relative "threaded"

module Pakyow
  module Runnable
    class Container
      module Strategies
        # @api private
        class Hybrid < Base
          def initialize(*)
            super

            @strategies = {
              forked: Forked.new, threaded: Threaded.new
            }

            @strategies.each_value do |strategy|
              strategy.instance_variable_set(:@queue, @queue)
            end
          end

          private def stop_service(service, signal)
            service_strategy(service).send(:stop_service, service, signal)
          end

          private def service_failed!(service)
            service_strategy(service).send(:service_failed!, service)
          end

          private def wait_for_service(service)
            service_strategy(service).send(:wait_for_service, service)
          end

          private def invoke_service(service)
            service_strategy(service).send(:invoke_service, service) do
              yield
            end
          end

          private def service_strategy(service)
            @strategies[service.strategy || default_strategy]
          end

          private def default_strategy
            ::Process.respond_to?(:fork) ? :forked : :threaded
          end
        end
      end
    end
  end
end
