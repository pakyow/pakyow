# frozen_string_literal: true

require "filewatcher"

require "pakyow/support/extension"

module Pakyow
  module Behavior
    module Watching
      extend Support::Extension

      apply_extension do
        class_state :on_change_matchers, default: {}
        class_state :watched_paths, default: []

        unfreezable :filewatcher, :filewatcher_thread

        after "run" do
          @filewatcher = Filewatcher.new(
            @watched_paths.map { |path|
              File.expand_path(path)
            }
          )

          @filewatcher_thread = Thread.new do
            @filewatcher.watch(&method(:watch_callback))
          end
        end

        on "shutdown" do
          @filewatcher.stop
          @filewatcher_thread.join
        end
      end

      class_methods do
        # Register a callback to be called when a file changes.
        #
        def on_change(matcher, &block)
          (@on_change_matchers[matcher] ||= []) << block
        end

        # Register one or more path for changes.
        #
        def watch(*paths, &block)
          @watched_paths.concat(paths).uniq!

          if block
            paths.each do |path|
              on_change(File.expand_path(path), &block)
            end
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

        # @api private
        def watch_callback(path, _event)
          change_callbacks(path).each do |callback|
            instance_exec(&callback)
          end
        end
      end
    end
  end
end
