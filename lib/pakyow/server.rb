# frozen_string_literal: true

require "pakyow/version"
require "pakyow/logger/colorizer"
require "pakyow/support/deep_freeze"

require "pakyow/processes/environment"

module Pakyow
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

    attr_reader :port, :host, :server

    def initialize(port: nil, host: nil, server: nil, standalone: false)
      @port       = port   || Pakyow.config.server.port
      @host       = host   || Pakyow.config.server.host
      @server     = server || Pakyow.config.server.name
      @standalone = standalone
      @instances  = []
    end

    def run
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
      exec "pakyow boot"
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

    def start_environment
      Processes::Environment.new(self).start_with_watch
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
  end
end
