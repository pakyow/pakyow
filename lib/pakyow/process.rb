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
      @listener = Listen.to(*self.class.watched_paths, ignore: Pakyow.config.server.ignore) { |modified, _added, _removed|
        modified.each do |path|
          self.class.change_callbacks(path).each(&:call)
        end

        restart
      }

      @listener.start
    end

    def start_and_watch
      start; watch
    end
  end
end
