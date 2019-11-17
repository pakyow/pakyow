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
          respawn_path = File.join(config.root, "tmp/respawn.txt")
          watch respawn_path do
            environment = File.read(respawn_path)

            ignore_changes do
              File.open(respawn_path, "w") do |file|
                file.truncate(0)
              end
            end

            respawn(environment)
          end

          # Other processes (e.g. apps) can touch this file to restart the server.
          #
          restart_path = File.join(config.root, "tmp/restart.txt")
          watch restart_path do
            environment = File.read(restart_path)

            ignore_changes do
              File.open(restart_path, "w") do |file|
                file.truncate(0)
              end
            end

            restart(environment)
          end

          # Automatically bundle.
          #
          watch File.join(config.root, "Gemfile") do
            Bundler.with_clean_env do
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

          # Close the bound endpoint so we can respawn on the same port.
          #
          @bound_endpoint.close

          # Finally, stop the process manager to invoke the respawn.
          #
          @process_manager.stop
        end
      end
    end
  end
end
