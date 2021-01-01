# frozen_string_literal: true

require "pakyow/support/deep_freeze"
require "pakyow/support/inspectable"

require_relative "../../notifier"

module Pakyow
  module Runnable
    class Container
      module Strategies
        # @api private
        class Base
          include Support::DeepFreeze
          insulate :backoff, :resolver

          include Support::Inspectable
          inspectable :@services

          def initialize
            @services = []
            @listeners = []
            @failed = false
            @stopping = false
            @notifier = nil
            @backoff = nil
            @handler = nil
            @resolver = nil
            @resolving = nil
          end

          def prepare(container)
            @notifier&.stop
            @notifier = Notifier.new

            @failed = false
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

            @notifier.listen do |event, **payload|
              case event
              when :message
                @listeners.each do |listener|
                  listener.call(payload[:message])
                end
              when :restart
                service_id = payload.delete(:service)

                if container.running? && (service = @services.find { |each_service| each_service.id == service_id })
                  manage_service(service)
                end
              when :reload
                container.performing :restart, **payload do
                  interrupt
                end
              when :exit
                service_id, service_status = payload.values_at(:service, :status)

                if (service = @services.find { |each_service| each_service.id == service_id })
                  unless service_status.success?
                    service.failed!

                    @failed = true
                  end

                  @services.delete(service)

                  if !stopping? && container.running? && service.restartable?
                    if service.status.success?
                      manage_service(service)
                    else
                      backoff_service(service)
                    end
                  end
                end
              when :stop
                @stopping = true

                @backoff&.stop
                @backoff = nil

                resolve(payload[:signal], timeout: container.options[:timeout])
              end
            end
          ensure
            @resolver&.stop
            @resolver = nil
          end

          def notify(message)
            @notifier.notify(:message, message: message)
          end

          def listen(&block)
            @listeners << block
          end

          def interrupt
            stop(:int)
          end

          def terminate
            stop(:term)
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
            @failed == false
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

          private def service_finished(service)
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

            wait_for_service(service)
          end

          private def run_service(service)
            wrap_service_run do
              Pakyow.async {
                begin
                  service.run
                rescue => error
                  Pakyow.houston(error)

                  service.failed!
                end
              }.wait
            ensure
              service_finished(service)
            end
          end

          private def wrap_service_run
            Fiber.new {
              yield
            }.resume
          end

          private def backoff_service(service)
            @backoff = Pakyow.async { |task|
              task.sleep(current_service_backoff(service))

              manage_service(service)
            }
          end

          private def resolve(event, timeout:)
            if @resolving
              event = case event
              when :int
                :term
              when :term
                :quit
              else
                event
              end
            end

            @failed = true if event == :quit

            @resolving = event

            @resolver&.stop
            @resolver = Pakyow.async { |task|
              start = current_time

              @services.each do |service|
                stop_service(service, event)
              end

              until (current_time - start) > timeout || @services.empty?
                task.sleep 0.25
              end

              if @services.empty?
                @notifier.stop
              else
                stop(event)
              end
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
