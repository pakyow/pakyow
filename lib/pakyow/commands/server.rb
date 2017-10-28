require "pakyow/version"
require "pakyow/logger/colorizer"

require "listen"
require "pastel"

module Pakyow
  # @api private
  module Commands
    # @api private
    class Server
      # Register a callback to be called when a file changes.
      #
      def self.on_change(path, &block)
        @on_change_paths ||= {}
        @on_change_paths[path] ||= []
        @on_change_paths[path] << block
      end

      # @api private
      def self.change_callbacks(path)
        @on_change_paths.fetch(path, [])
      end

      on_change "Gemfile" do
        Process.waitpid(Process.spawn("bundle install"))
      end

      def initialize(env: nil, port: nil, host: nil, server: nil, reload: true)
        @env    = env
        @port   = port   || Pakyow.config.server.port
        @host   = host   || Pakyow.config.server.host
        @server = server || Pakyow.config.server.default
        @reload = reload
      end

      def run
        if @reload
          puts colorizer.red(header_text)
          puts colorizer.black.on_white.bold(running_text)

          preload
          start_process
          trap_interrupts
          watch_for_changes

          sleep
        else
          start_server
        end
      end

      protected

      def preload
        require "bundler/setup"
      end

      def start_process
        if Process.respond_to?(:fork)
          @pid = Process.fork do
            start_server
          end
        else
          @pid = Process.spawn("bundle exec pakyow server --no-reload")
        end
      end

      def stop_process
        Process.kill("INT", @pid) if @pid
      end

      def restart_process
        stop_process; start_process
      end

      def start_server
        require "./config/environment"
        Pakyow.setup(env: @env).run(port: @port, host: @host, server: @server)
      end

      def trap_interrupts
        Pakyow::STOP_SIGNALS.each do |signal|
          trap(signal) {
            stop_process; exit
          }
        end
      end

      def watch_for_changes
        listener = Listen.to(".") do |modified, added, removed|
          modified.each do |path|
            path = path.split(File.expand_path(".") + "/", 2)[1]
            self.class.change_callbacks(path).each(&:call)
          end

          restart_process
        end

        listener.start
      end

      def header_text
        File.read(
          File.expand_path("../output/splash.txt", __FILE__)
        ).gsub!("{v}", "v#{VERSION}")
      end

      def running_text
        " running on #{@server} → http://#{@host}:#{@port} \n"
      end

      def colorizer
        @colorizer ||= Pastel.new
      end
    end
  end
end
