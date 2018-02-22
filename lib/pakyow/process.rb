# frozen_string_literal: true

require "filewatcher"

require "pakyow/support/class_state"

module Pakyow
  class Process
    extend Support::ClassState
    class_state :on_change_matchers, default: {},  inheritable: true
    class_state :watched_paths,      default: [],  inheritable: true
    class_state :dependent_on,       default: nil, inheritable: true

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

    def stop
      ::Process.kill("INT", @pid) if @pid
      @server.stopped(self)
    end

    def restart
      stop; start
    end

    def watch
      Thread.new do
        Filewatcher.new(self.class.watched_paths).watch(&method(:watch_callback))
      end
    end

    def watch_callback(path, _event)
      callbacks_for_path = self.class.change_callbacks(path)

      if callbacks_for_path.any?
        callbacks_for_path.each do |callback|
          instance_exec(&callback)
        end

        return
      end

      restart
    end

    def start_and_watch
      start; watch
    end
  end
end
