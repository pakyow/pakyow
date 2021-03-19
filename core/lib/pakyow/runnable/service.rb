# frozen_string_literal: true

require "core/async"

require "pakyow/support/class_state"
require "pakyow/support/handleable"
require "pakyow/support/inspectable"
require "pakyow/support/makeable"

module Pakyow
  module Runnable
    # Performs work in a system service created by a parent container.
    #
    # @example
    #   Pakyow.container :some_container do
    #     service :some_service do
    #       def perform
    #         until stopped? do
    #           puts "hello"
    #           sleep 1
    #         end
    #       end
    #
    #       def shutdown
    #         # Do something on shutdown.
    #       end
    #     end
    #   end
    #
    # = Restartability
    #
    # Services are restartable by default, meaning the container will restart services that exit
    # until the container itself is stopped. Restartability can be disabled for a service by
    # defining the service with `restartable: false`:
    #
    #   Pakyow.container :some_container do
    #     service :some_service, restartable: false do
    #       ...
    #     end
    #   end
    #
    # Restartability can be determined at runtime by overloading the `restartable?` instance method:
    #
    #   Pakyow.container :some_container do
    #     service :some_service do
    #       def restartable?
    #         [true, false].sample
    #       end
    #     end
    #   end
    #
    # = Service Limits
    #
    # Services can be started any number of times by default, as defined by the container's current
    # formation. Limits can be imposed on a service by defining the service with `limit: {n}`:
    #
    #   Pakyow.container :some_container do
    #     service :some_service, limit: 1 do
    #       ...
    #     end
    #   end
    #
    # Limits can be determined at runtime by overloading the `limit` instance method:
    #
    #   Pakyow.container :some_container do
    #     service :some_service do
    #       def limit
    #         [1, 2].sample
    #       end
    #     end
    #   end
    #
    # = Prerun / Postrun
    #
    # Services running in a top-level container have their `prerun` method invoked when the container
    # runs. This methods receives the container's run options, giving the service an opportunity to
    # add its own options for later use. Similarly, `postrun` is called  when the container stops.
    #
    class Service
      class Status
        include Support::Inspectable
        inspectable :@status

        def initialize(status = :unknown)
          @status = status
        end

        def unknown?
          @status == :unknown
        end

        def success?
          @status == :success
        end

        def failed?
          @status == :failed
        end

        def success!
          @status = :success
        end

        def failed!
          @status = :failed
        end
      end

      include Is::Async

      extend Support::ClassState
      class_state :strategy, default: nil, inheritable: true
      class_state :restartable, default: true, inheritable: true
      class_state :limit, default: nil, inheritable: true
      class_state :count, default: 1, inheritable: true

      include Support::Handleable
      include Support::Makeable

      include Support::Inspectable
      inspectable :@options, :@metadata, :@status

      attr_reader :id, :options, :metadata, :reference, :status

      # @api private
      attr_writer :reference

      def initialize(**options)
        @id = SecureRandom.hex(4)
        @options = options
        @metadata = {}
        @reference = nil
        @status = Status.new
        @notifier = nil
        @__stopped = false
        @__retries = 0
        @__blocked = true
      end

      def initialize_copy(_)
        super

        @options = @options.dup
        @metadata = @metadata.dup
        @status = @status.dup
      end

      # Marks a service as having failed.
      #
      def failed!
        @status.failed!

        @options[:parent]&.failed!
      end

      # Marks a service as having succeeded.
      #
      def success!
        @status.success!
      end

      # Returns the service strategy, or nil for the default strategy. Used only by the hybrid strategy.
      #
      def strategy
        self.class.strategy
      end

      # Returns the service limit, or nil for no limit. This value takes precedence over formations.
      #
      def limit
        self.class.limit
      end

      # Returns the service count.
      #
      def count
        self.class.count
      end

      # Prepares the service for running. Expected to be called from the container process.
      #
      def prepare
        @notifier = Notifier.new

        self
      end

      # Runs the service, calling `perform`.
      #
      def run
        async do
          @notifier.listen do |event|
            case event
            when :stop
              @notifier.stop
              perform_stop
            end
          end
        end

        await do
          future = async do
            perform
          rescue => error
            Pakyow.houston(error)

            failed!
          ensure
            future&.cancel
          end

          @__blocked = false
        end

        if @notifier&.running?
          @notifier.stop
        end
      end

      # Stops the service, calling `shutdown`.
      #
      def stop
        if @__blocked
          perform_stop
        else
          @notifier&.notify(:stop)
        end
      end

      private def perform_stop
        @__stopped = true
        shutdown
      end

      # Returns true if the service is restartable.
      #
      def restartable?
        self.class.restartable == true
      end

      # Returns true if the service is stopped.
      #
      def stopped?
        @__stopped == true
      end

      # Called when the service is run.
      #
      def perform
        # implemented by subclasses
      end

      # Called when the service is stopped.
      #
      def shutdown
        # implemented by subclasses
      end

      # Returns the service logger.
      #
      def logger
        Pakyow.logger
      end

      class << self
        def run(**options)
          instance = new(**options)
          instance.run
          instance
        end

        def prerun(options)
          # implemented by subclasses
        end

        def postrun(options)
          # implemented by subclasses
        end
      end
    end
  end
end
