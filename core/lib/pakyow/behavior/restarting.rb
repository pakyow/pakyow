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
            if CLI.system("bundle install", logger_key: "bndl").success?
              restart
            end
          end

          # Watch all files for changes.
          #
          watch File.join(config.root)

          # Explicitly watch environment files.
          #
          watch File.join(config.root, ".env*")

          # Ignore some common paths that shouldn't trigger restarts.
          #
          ignore File.join(config.root, ".git")
          ignore File.join(config.root, "node_modules")
          ignore File.join(config.root, "tmp/cache")

          # Restart when any file changes.
          #
          changed do |diff|
            unless diff.include?(File.join(config.root, "Gemfile")) || diff.include?(File.join(config.root, "Gemfile.lock"))
              restart
            end
          end
        end

        before "setup" do
          if env?(:development) || env?(:prototype)
            action :restart, Actions::Restart
          end
        end
      end
    end
  end
end
