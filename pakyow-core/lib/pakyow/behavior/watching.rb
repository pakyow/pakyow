# frozen_string_literal: true

require "pakyow/support/deprecatable"
require "pakyow/support/extension"
require "pakyow/support/system"

require_relative "../filewatcher"
require_relative "running/ensure_booted"

module Pakyow
  module Behavior
    # Environment behavior for reacting to changes in the filesystem.
    #
    module Watching
      extend Support::Extension

      apply_extension do
        class_state :__filewatcher_changes, default: {}
        class_state :__filewatcher_ignores, default: []
        class_state :__filewatcher_watches, default: []

        # Watches the filesystem, reacting to any changes.
        #
        container(:environment).service :watcher, restartable: false, limit: 1 do
          include Running::EnsureBooted

          if Support::System.ruby_version < "2.7.0"
            def initialize(*)
              __common_watching_behavior_initializer; super
            end
          else
            def initialize(*, **)
              __common_watching_behavior_initializer; super
            end
          end

          private def __common_watching_behavior_initializer
            @filewatcher = Filewatcher.new
          end

          def count
            options[:config].watcher.count
          end

          def perform
            ensure_booted do
              Pakyow.__filewatcher_changes.each do |matcher, blocks|
                blocks.each do |options|
                  @filewatcher.callback(matcher, snapshot: options[:snapshot], &options[:block])
                end
              end

              Pakyow.__filewatcher_ignores.each do |path|
                @filewatcher.ignore(path)
              end

              Pakyow.__filewatcher_watches.each do |path|
                @filewatcher.watch(path)
              end
            end

            @filewatcher.perform
          end

          def shutdown
            @filewatcher.stop

            # Wait on the filewatcher to fully stop.
            #
            sleep @filewatcher.interval
          end
        end
      end

      class_methods do
        # Register a callback to be called when a file changes.
        #
        def changed(matcher = nil, snapshot: false, &block)
          (__filewatcher_changes[matcher] ||= []) << { block: block, snapshot: snapshot }
        end

        def on_change(matcher = nil, &block)
          change(matcher, &block)
        end

        extend Support::Deprecatable
        deprecate :on_change, solution: "prefer `changed'"

        # Register one or more path for changes.
        #
        def watch(*paths, &block)
          paths.each do |path|
            __filewatcher_watches << path
            changed(path, &block) if block
          end
        end

        # Ignore one or more paths when watching for changes.
        #
        def ignore(*paths)
          paths.each do |path|
            __filewatcher_ignores << path
          end
        end
      end
    end
  end
end
