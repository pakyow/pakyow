# frozen_string_literal: true

require "pakyow/support/cli/runner"
require "pakyow/support/deprecatable"
require "pakyow/support/extension"

module Pakyow
  module Behavior
    module Restarting
      extend Support::Extension

      apply_extension do
        on "run" do
          # Automatically bundle.
          #
          watch File.join(config.root, "Gemfile") do
            Bundler.with_original_env do
              Support::CLI::Runner.new(message: "Bundling").run("bundle install")
            end
          end

          # Watch all files for changes.
          #
          watch File.join(config.root, "**", "*")

          # Restart when any file changes.
          #
          changed snapshot: true do
            restart
          end
        end
      end

      class_methods do
        def respawn(env: Pakyow.env)
          restart(env: env)
        end

        extend Support::Deprecatable
        deprecate :respawn, solution: "prefer `Pakyow.restart'"
      end
    end
  end
end
