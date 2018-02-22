# frozen_string_literal: true

require "pastel"

require "pakyow/version"
require "pakyow/logger/colorizer"
require "pakyow/support/deep_freeze"

require "pakyow/processes/environment"

module Pakyow
  # @api private
  module Commands
    # @api private
    class Server
      class << self
        def register_process(process)
          (@processes ||= []) << process
        end

        def processes
          @processes
        end
      end

      extend Support::DeepFreeze
      unfreezable :instances

      attr_reader :env, :port, :host, :server

      def initialize(env: nil, port: nil, host: nil, server: nil, standalone: false)
        @env        = env
        @port       = port   || Pakyow.config.server.port
        @host       = host   || Pakyow.config.server.host
        @server     = server || Pakyow.config.server.default
        @standalone = standalone
        @instances  = []
      end

      def run
        preload

        Pakyow.after :boot, exec: false do
          puts_running_text
        end

        if @standalone
          start_environment
        else
          start_processes
          trap_interrupts
          start_environment
        end
      end

      def started(process)
        @instances << process
      end

      def stopped(process)
        @instances.delete(process)
      end

      def start_instance(instance)
        instance.start_with_watch
      end

      def respawn
        stop_processes
        # TODO: take into account environment, other options that can be specified
        exec("bundle exec pakyow server")
      end

      def stop_dependent_processes(dependent_on)
        @instances.each do |instance|
          if instance.class.dependent_on == dependent_on
            instance.stop
          end
        end
      end

      def standalone?
        @standalone == true
      end

      protected

      def preload
        require "./config/environment"
      end

      def start_environment
        Pakyow::Processes::Environment.new(self).start_with_watch
      end

      def start_processes
        self.class.processes.to_a.each do |process|
          start_instance(process.new(self))
        end
      end

      def stop_processes
        @instances.each do |instance|
          stop_dependent_processes(instance.class)
          instance.stop
        end
      end

      def restart_processes
        @instances.each(&:restart)
      end

      def trap_interrupts
        Pakyow::STOP_SIGNALS.each do |signal|
          trap(signal) {
            stop_processes; exit
          }
        end
      end

      def puts_running_text
        return if instance_variable_defined?(:@displayed)
        puts colorizer.black.on_white.bold(running_text) + "\n"
        @displayed = true
      end

      def running_text
        " running on #{@server} → http://#{@host}:#{@port} "
      end

      def colorizer
        @colorizer ||= Pastel.new
      end
    end
  end
end
