# frozen_string_literal: true

require "pakyow/version"
require "pakyow/logger/colorizer"

require "listen"
require "pastel"

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

        if @standalone
          Pakyow.after :boot, exec: false do
            puts_running_text
          end

          start_standalone_server
        else
          start_processes
          trap_interrupts
          puts_running_text

          sleep
        end
      end

      def start_standalone_server
        Pakyow.setup(env: @env).run(port: @port, host: @host, server: @server)
      end

      def started(process)
        @instances << process
      end

      def stopped(process)
        @instances.delete(process)
      end

      def start_instance(instance)
        instance.start_and_watch
      end

      def respawn
        stop_processes
        exec("bundle exec pakyow server")
      end

      protected

      def preload
        require "./config/environment"
        Pakyow.stage(env: @env)
      end

      def start_processes
        self.class.processes.each do |process|
          start_instance(process.new(self))
        end
      end

      def stop_processes
        @instances.each(&:stop)
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

  require "pakyow/processes/server"
end
