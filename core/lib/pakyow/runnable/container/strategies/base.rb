# frozen_string_literal: true

require "pakyow/support/inspectable"

require_relative "../../notifier"

module Pakyow
  module Runnable
    class Container
      module Strategies
        # @api private
        class Base
          include Support::Inspectable
          inspectable :@services

          def initialize
            @services = []
            @statuses = []
            @queue = Queue.new
            @lock = Mutex.new
            @notifier = nil
            @stopping = false
          end

          def run(container)
            @statuses = []

            @notifier&.stop
            @notifier = Notifier.new(container: container, &method(:handle_notification).to_proc)

            container.formation.each.map { |service_name, desired_service_count|
              service_instance = container.services(service_name).new(**container.options)
              desired_service_count ||= (service_instance.count || 1)
              service_limit = service_instance.limit

              service_count = if service_limit.nil? || service_instance.limit >= desired_service_count
                desired_service_count
              else
                Pakyow.logger.warn "attempted to run service `#{container.class.object_name.name}.#{service_name}' #{desired_service_count} times, but was limited to #{service_limit}"

                service_limit
              end

              [service_instance, service_count]
            }.each do |service_instance, service_count|
              service_count.times do |index|
                manage_service(service_instance.dup)
              end
            end
          end

          def wait(container)
            if @services.any?
              while (message = @queue.pop)
                event, service = message

                case event
                when :restart
                  if container.running?
                    manage_service(service)
                  end
                when :exit
                  @lock.synchronize do
                    @services.delete(service)
                  end

                  if !stopping? && container.running? && service.restartable?
                    if service.status.success?
                      manage_service(service)
                    else
                      backoff_service(service)
                    end
                  elsif @services.empty?
                    break
                  end
                end
              end
            end
          end

          def interrupt
            stop("INT")
          end

          def terminate
            stop("TERM")
          end

          def restart(**payload)
            @notifier.notify(:restart, **payload)
          end

          def stop(signal)
            @stopping = true

            @services.each do |service|
              stop_service(service, signal)
            end

            @notifier&.stop
          end

          def stopping?
            @stopping == true
          end

          def success?
            @statuses.all?(&:success?)
          end

          def finish
            # Implemented by subclasses.
          end

          private def stop_service(service, signal)
            # Implemented by subclasses.
          end

          private def wait_for_service(service)
            # Implemented by subclasses.
          end

          private def invoke_service(service)
            # Implemented by subclasses.
          end

          private def service_failed!
            # Implemented by subclasses.
          end

          private def manage_service(service)
            update_service_metadata(service)

            register_service_reference(service, invoke_service(service) { run_service(service) })
          end

          private def update_service_metadata(service)
            @lock.synchronize do
              if service.metadata.include?(:retries)
                service.metadata[:retries] += 1
              else
                service.metadata[:retries] = 0
              end

              service.metadata[:started_at] = current_time
            end
          end

          private def register_service_reference(service, reference)
            @lock.synchronize do
              service.reference = reference

              @services << service
              @statuses << service.status
            end

            wait_for_service(service)
          end

          private def run_service(service)
            Fiber.new {
              begin
                Signal.trap(:HUP) do
                  if container.restartable?
                    raise Restart
                  end
                end

                Signal.trap(:INT) do
                  raise Interrupt
                end

                Signal.trap(:TERM) do
                  raise Terminate
                end

                Pakyow.async logger: service.logger do
                  service.run
                rescue => error
                  Pakyow.houston(error)

                  service_failed!(service)
                end

                service.stop
              rescue Terminate
              rescue Interrupt
                service.stop
              end
            }.resume
          rescue Interrupt
            # Catch interrupts that occur before the fiber runs.
          end

          private def handle_notification(event, **payload)
            case event
            when :restart
              payload.delete(:container).performing :restart, **payload do
                interrupt
              end
            end
          end

          private def backoff_service(service)
            Thread.new do
              sleep current_service_backoff(service)
              @queue.push([:restart, service])
            end
          end

          MINIMUM_BACKOFF = 0.5

          private def current_service_backoff(service)
            [MINIMUM_BACKOFF, seconds_since_service_started(service)].max * service.metadata[:retries]
          end

          private def seconds_since_service_started(service)
            current_time - service.metadata[:started_at]
          end

          private def current_time
            ::Process.clock_gettime(::Process::CLOCK_MONOTONIC)
          end
        end
      end
    end
  end
end
