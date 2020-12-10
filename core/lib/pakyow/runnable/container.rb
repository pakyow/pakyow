# frozen_string_literal: true

require "pakyow/support/class_state"
require "pakyow/support/deep_freeze"
require "pakyow/support/definable"
require "pakyow/support/hookable"
require "pakyow/support/inspectable"
require "pakyow/support/makeable"

require_relative "errors"
require_relative "formation"
require_relative "service"

require_relative "container/strategies/base"

module Pakyow
  module Runnable
    # Runs and manages one or more services.
    #
    # = Management Strategy
    #
    # Processes are managed with one of two strategies:
    #
    #   * `:forked` - Each service runs in a fork of the current service.
    #
    #   * `:threaded` - Each service runs in a thread within the current service.
    #
    #   * `:hybrid` - Each service runs in its defined strategy, or the best available default.
    #
    # Hybrid is the default strategy, where services run in their defined strategy or the best
    # available (Forked on supported platforms, falling back to Threaded). The container strategy
    # can be specified explicitly by passing the `:strategy` runtime option.
    #
    # It's expected that only one container is running per process or thread.
    #
    # = Automatic Restarts
    #
    # Containers are restartable by default, meaning they run until stopped. In practice, this means
    # that if one or all container services exit, the container will automatically restart them.
    #
    # Automatic restarts can be disabled for containers at runtime by passing `restartable: false`
    # as a run option. Restartability can be completely disabled for a container by defining the
    # container with `restartable: false`:
    #
    #   Pakyow.container :some_container, restartable: false do
    #     ..
    #   end
    #
    # If the container is defined as unrestartable, the `:restartable` runtime option is ignored.
    #
    # = Failed Process Backoffs
    #
    # If a restartable service fails, it will be restarted using an exponential backoff. The backoff
    # time is calculated by multiplying the time it took the service to fail by the current retry
    # count. Container will always wait at least 500 milliseconds before restarting a service, even
    # if the service failed immediately.
    #
    # = Signal Handling
    #
    # Containers handle these service signals for you:
    #
    #   * `INT`: Stops the container, giving its services an opportunity to shutdown.
    #
    #   * `TERM`: Stops the container without waiting on its services to shutdown.
    #
    #   * `HUP`: Restarts the container along with its services.
    #
    # = Formations
    #
    # Containers can be run with a formation specifying which services to run. If a formation is
    # unspecified, a single instance of all services are run.
    #
    # Run all services with service-defined counts:
    #
    #   Pakyow.container(:some_container).run(formation: Pakyow::Runnable::Formation.all)
    #
    # Specify a formation by passing a formation object through the `:formation` run option.
    #
    # Run 3 instances of all services:
    #
    #   Pakyow.container(:some_container).run(formation: Pakyow::Runnable::Formation.all(3))
    #
    # Run 3 instances of `service_1` and 1 instance of `service_2`:
    #
    #   Pakyow.container(:some_container).run(formation: Pakyow::Runnable::Formation.build { |formation|
    #     formation.run(:service_1, 3)
    #     formation.run(:service_2, 1)
    #   })
    #
    # If a service is unspecified in a formation, it will not be run.
    #
    # = Nested Container Behavior
    #
    # Containers assume they are running as a top-level container. When running a container within
    # another service, pass the service as the `parent` option. This tells the container that it is
    # running as a nested container. Prerun / Postrun methods won't be called on services running in
    # a nested container and the container will report its status to the parent service.
    #
    class Container
      class << self
        def insulated?
          true
        end
      end

      extend Support::ClassState
      class_state :restartable, default: true, inheritable: true
      class_state :toplevel_pid, default: ::Process.pid, inheritable: true

      include Support::Definable
      include Support::Makeable

      include Support::Inspectable
      inspectable :@running, :@options, :@strategy

      definable :service, Service

      include Support::Hookable
      events :fork, :restart

      before "fork" do
        Pakyow.call_hooks(:before, :fork)
      end

      after "fork" do
        Pakyow.call_hooks(:after, :fork)
      end

      attr_reader :options

      # @api private
      attr_reader :strategy

      # Supported options include:
      #
      #   * strategy: `:forked`, `:threaded`, or `:hybrid` (defaults to `:hybrid`)
      #   * formation: the formation to run (defaults to `Pakyow::Runnable::Formation.all`)
      #   * parent: the parent service or container that this container is running in
      #
      # All options are passed through to the `perform` method of each service run within this container.
      #
      def initialize(**options)
        @running = nil
        @options = {}
        @strategy = nil
        @__preran = []

        @options = finalize_options(options)
        validate_formation!
        @strategy = self.class.load_strategy(options[:strategy])
      end

      # Runs the container.
      #
      def run
        unless running?
          prerun!

          @running = true

          Signal.trap(:HUP) do
            if restartable?
              @strategy.interrupt
            end
          end

          Signal.trap(:INT) do
            @running = false

            # Go ahead and interrupt children, since we might be interrupting due to a restart in which
            # case child services will not have received the interrupt signal from the system.
            #
            @strategy.interrupt
          end

          Signal.trap(:TERM) do
            @running = false

            # Terminating means we don't give services a chance to stop.
            #
            @strategy.terminate
          end

          yield self if block_given?

          Pakyow.async {
            while running?
              @strategy.prepare(self)
              @strategy.run(self)
              @strategy.wait(self)

              unless restartable?
                stop
              end
            end
          }.wait

          if toplevel_pid?
            success?
          else
            ::Process.exit(success?)
          end
        end
      rescue SignalException => error
        raise error unless toplevel_pid?
      ensure
        stop
        postrun!
      end

      # Restarts the container.
      #
      def restart(**payload)
        if running? && restartable?
          @strategy.restart(**payload)
        end
      end

      # Stops the container.
      #
      def stop
        if running?
          @running = false

          @strategy.interrupt
        end
      end

      # Returns true if the container is running or has run successfully.
      #
      def success?
        if @running.nil?
          nil
        else
          @strategy.success?
        end
      end

      # Returns true if the container is running.
      #
      def running?
        @running == true
      end

      # Returns the formation for this container.
      #
      def formation
        if @options[:formation].service?(:all)
          expand_formation(@options[:formation])
        else
          @options[:formation]
        end
      end

      private def restartable?
        return false unless running?
        return false if self.class.restartable == false
        @options.fetch(:restartable) { self.class.restartable }
      end

      private def toplevel?
        @options[:parent].nil?
      end

      private def toplevel_pid?
        ::Process.pid == self.class.toplevel_pid
      end

      private def expand_formation(all)
        all_count = all.count(:all)

        Formation.build { |formation|
          services.each do |service|
            formation.run(service.object_name.name, all_count)
          end
        }
      end

      private def validate_formation!
        formation.each_service do |service_name|
          unless services(service_name)
            error = Pakyow::UnknownService.new_with_message(service: service_name, container: self.class.object_name.name)
            error.context = self
            raise error
          end
        end
      end

      private def prerun!
        return unless toplevel?

        formation.each_service do |service_name|
          service = services(service_name)
          service.prerun(@options)
          @__preran << service
        rescue => error
          Pakyow.houston(error)
        end
      end

      private def postrun!
        return unless toplevel?

        @__preran.each do |service|
          service.postrun(@options)
        rescue => error
          Pakyow.houston(error)
        end
      end

      private def finalize_options(options)
        options[:strategy] = strategy_option(options[:strategy])
        options[:formation] = formation_option(options[:formation])
        options
      end

      private def strategy_option(strategy)
        strategy || :hybrid
      end

      private def formation_option(formation)
        traverse_formation(formation || Pakyow::Runnable::Formation.all)
      end

      private def traverse_formation(formation)
        return formation if formation.container == self.class.object_name.name
        formation.formation(self.class.object_name.name) || formation
      end

      class << self
        def run(**options, &block)
          new(**options).run(&block)
        end

        # @api private
        def load_strategy(strategy)
          require "pakyow/runnable/container/strategies/#{strategy}"
          Strategies.const_get(Support.inflector.camelize(strategy)).new
        rescue LoadError => error
          # TODO: Establish a pattern for dynamic loading and handling resulting errors. In this case
          # we want to raise a specific error and list out all available strategies. There are similar
          # cases elsewhere, such as loading adapters in pakyow/data.
          #
          raise Pakyow::UnknownContainerStrategy.build(error, strategy: strategy)
        end
      end
    end
  end
end
