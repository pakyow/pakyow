# frozen_string_literal: true

require "pakyow/support/extension"

module Pakyow
  module Behavior
    module Restarting
      extend Support::Extension

      apply_extension do
        on "run" do
          @respawn = false

          # Other processes (e.g. apps) can touch this file to restart the server.
          #
          watch File.join(config.root, "tmp/restart.txt") do
            restart
          end

          # Automatically bundle.
          #
          watch File.join(config.root, "Gemfile") do
            Bundler.with_original_env do
              Support::CLI::Runner.new(message: "Bundling").run("bundle install")
            end
          end

          # Respawn when the bundle changes.
          #
          watch File.join(config.root, "Gemfile.lock") do
            respawn
          end

          # Respawn when something about the environment changes.
          #
          watch "#{Pakyow.config.environment_path}.rb" do
            respawn
          end
        end
      end

      class_methods do
        def respawn
          # Set the respawn flag and stop the process manager.
          # Pakyow will check the flag and respawn from the main thread.
          #
          @respawn = true
          @bound_endpoint.close
          @process_manager.stop
        end
      end
    end
  end
end
