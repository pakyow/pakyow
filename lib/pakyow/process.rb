# frozen_string_literal: true

require "pakyow/support/class_level_state"

module Pakyow
  class Process
    extend Support::ClassLevelState
    class_level_state :on_change_matchers, default: {}, inheritable: true
    class_level_state :watched_paths,      default: [], inheritable: true

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
      @listener = Listen.to(*self.class.watched_paths, ignore: Pakyow.config.server.ignore, &method(:watch_callback))
      @listener.start
    end

    def start_and_watch
      start; watch
    end

    def watch_callback(modified, _added, _removed)
      return if modified.empty?

      modified.each do |path|
        callbacks_for_path = self.class.change_callbacks(path)
        if callbacks_for_path.any?
          callbacks_for_path.each do |callback|
            instance_exec(&callback)
          end

          return
        end
      end

      restart
    end
  end
end
