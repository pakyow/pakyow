# frozen_string_literal: true

require "filewatcher"

require "pakyow/support/class_state"

module Pakyow
  # Represents a process that can be restarted when conditions are met.
  #
  class Process
    extend Support::ClassState
    class_state :on_change_matchers, default: {},  inheritable: true
    class_state :watched_paths,      default: [],  inheritable: true
    class_state :dependent_on,       default: nil, inheritable: true, getter: false

    class << self
      # Register a callback to be called when a file changes.
      #
      def on_change(matcher, &block)
        (@on_change_matchers[matcher] ||= []) << block
      end

      # Register one or more path for changes.
      #
      def watch(*paths)
        @watched_paths.concat(paths).uniq!
      end

      # Makes this process dependent on another process.
      #
      def dependent_on(other_process_class = nil)
        if other_process_class.nil?
          @dependent_on
        else
          @dependent_on = other_process_class
        end
      end

      # @api private
      def change_callbacks(path)
        @on_change_matchers.each_with_object([]) { |(matcher, blocks), matched_blocks|
          if matcher.match?(path)
            matched_blocks.concat(blocks)
          end
        }
      end
    end

    def initialize(server)
      @server = server
    end

    def start
      @server.started(self)
    end

    def stop(_exiting = false)
      if @pid
        ::Process.kill("TERM", @pid)
        ::Process.waitpid(@pid)
        @pid = nil
      end

      @server.stopped(self)
    end

    def restart
      # Don't allow a forked process to issue a restart.
      #
      if ::Process.pid == @server.master_pid
        stop; start
      end
    end

    def watch
      Thread.new do
        Filewatcher.new(self.class.watched_paths).watch(&method(:watch_callback))
      end
    end

    def watch_callback(path, _event)
      callbacks = self.class.change_callbacks(path)

      if callbacks.any?
        callbacks.each do |callback|
          instance_exec(&callback)
        end
      else
        restart
      end
    end

    def start_with_watch
      watch; start
    end
  end
end
