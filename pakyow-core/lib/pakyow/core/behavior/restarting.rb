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
          if config.process.trigger_restarts
            config.process.watched_paths << File.join(config.src, "**/*.rb")

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
end
