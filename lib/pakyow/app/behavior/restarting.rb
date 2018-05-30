# frozen_string_literal: true

require "fileutils"

require "pakyow/support/silenceable"
Pakyow::Support::Silenceable.silence_warnings do
  require "filewatcher"
end

require "pakyow/support/extension"

module Pakyow
  module Behavior
    # Handles triggering restarts in the parent process.
    #
    module Restarting
      extend Support::Extension

      apply_extension do
        settings_for :process do
          setting :trigger_restarts
          setting :watched_paths, []

          defaults :development do
            setting :trigger_restarts, true
          end

          defaults :prototype do
            setting :trigger_restarts, true
          end
        end

        after :initialize do
          setup_for_restarting
        end

        # Setting up for restarting even after the app fails to initialize lets
        # the developer fix the problem and let the server restart on its own.
        #
        after :rescue do
          setup_for_restarting
        end
      end

      def setup_for_restarting
        if config.process.trigger_restarts
          config.process.watched_paths << File.join(config.src, "**/*.rb")
          config.process.watched_paths << File.join(config.lib, "**/*.rb")

          # FIXME: this doesn't need to be hardcoded, but instead determined
          # from the source location when registered with the environment
          config.process.watched_paths << "./config/application.rb"

          Thread.new do
            Filewatcher.new(config.process.watched_paths).watch do |_path, _event|
              FileUtils.mkdir_p "./tmp"
              FileUtils.touch "./tmp/restart.txt"
            end
          end
        end
      end
    end
  end
end
