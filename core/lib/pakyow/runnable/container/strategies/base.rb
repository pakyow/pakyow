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
            @stopping = false
            @notifier = nil
            @backoff = nil
            @handler = nil
          end

          def prepare(container)
            @statuses = []

            @notifier&.stop
            @notifier = Notifier.new
          end

          def run(container)
            container.performing :fork do
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
          end

          def wait(container)
            return if @services.empty?

            signal = "INT"

            @notifier.listen do |event, **payload|
              case event
              when :restart
                service_id = payload.delete(:service)

                if container.running? && (service = @services.find { |each_service| each_service.object_id == service_id })
                  manage_service(service)
                end
              when :reload
                container.performing :restart, **payload do
                  interrupt
                end
              when :exit
                service_id = payload.delete(:service)

                if (service = @services.find { |each_service| each_service.object_id == service_id })
                  @services.delete(service)

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
              when :stop
                @stopping = true

                @backoff&.stop
                @backoff = nil

                signal = payload[:signal]

                break
              end
            end
          ensure
            # Handle ungraceful exits by ensuring that we stop all running services.
            #
            @services.each do |service|
              stop_service(service, signal)
            end

            # Wait on the services to exit.
            #
            Async::Task.current.async { |task|
              until !@services.any? { |service| service.status.unknown? }
                task.sleep 0.1
              end
            }.wait
          end

          def interrupt
            stop("INT")
          end

          def terminate
            stop("TERM")
          end

          def restart(**payload)
            @notifier.notify(:reload, **payload)
          end

          def stop(signal)
            @notifier.notify(:stop, signal: signal)
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
            if service.metadata.include?(:retries)
              service.metadata[:retries] += 1
            else
              service.metadata[:retries] = 0
            end

            service.metadata[:started_at] = current_time
          end

          private def register_service_reference(service, reference)
            service.reference = reference

            @services << service
            @statuses << service.status

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

                Pakyow.async {
                  begin
                    service.run
                  rescue => error
                    Pakyow.houston(error)

                    service_failed!(service)
                  end
                }.wait

                service.stop
              rescue Terminate
              rescue Interrupt
                service.stop
              end
            }.resume
          rescue Interrupt
            # Catch interrupts that occur before the fiber runs.
          end

          private def backoff_service(service)
            @backoff = Async::Task.current.async { |task|
              task.sleep(current_service_backoff(service))

              manage_service(service)
            }
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
