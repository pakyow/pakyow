# frozen_string_literal: true

require "pakyow/support/extension"

module Pakyow
  module Behavior
    module Restarting
      extend Support::Extension

      apply_extension do
        on "run" do
          @respawn = false

          # Other processes (e.g. apps) can touch this file to respawn the process.
          #
          watch "./tmp/respawn.txt" do
            respawn(File.read("./tmp/respawn.txt"))
          end

          # Other processes (e.g. apps) can touch this file to restart the server.
          #
          watch "./tmp/restart.txt" do
            restart(File.read("./tmp/restart.txt"))
          end

          # Automatically bundle.
          #
          watch "./Gemfile" do
            Bundler.with_clean_env do
              Support::CLI::Runner.new(message: "Bundling").run("bundle install")
            end
          end

          # Respawn when the bundle changes.
          #
          watch "./Gemfile.lock" do
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
        def respawn(environment = nil)
          # Set the respawn flag and stop the process manager.
          # Pakyow will check the flag and respawn from the main thread.
          #
          @respawn = true

          # Set the environment to respawn into, if it was passed.
          #
          unless environment.nil? || environment.empty?
            @respawn_environment = environment.strip.to_sym
          end

          # Finally, stop the process manager to invoke the respawn.
          #
          @process_manager.stop
        end
      end
    end
  end
end
