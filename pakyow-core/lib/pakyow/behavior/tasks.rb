# frozen_string_literal: true

require "pakyow/support/deprecator"
require "pakyow/support/extension"

require "pakyow/task"

module Pakyow
  module Behavior
    module Tasks
      extend Support::Extension

      apply_extension do
        class_state :tasks, default: []

        configurable :tasks do
          setting :paths, ["./tasks", File.expand_path("../../tasks", __FILE__)]
          setting :prelaunch, []
        end

        config.deprecate :tasks, solution: "use `config.commands'"

        on "load" do
          tasks.clear

          Support::Deprecator.global.ignore do
            config.tasks.paths.uniq.each_with_object(tasks) do |tasks_path, tasks|
              Dir.glob(File.join(File.expand_path(tasks_path), "**/*.rake")).each do |task_path|
                tasks.concat(Pakyow::Task::Loader.new(task_path).__tasks)
              end
            end
          end
        end
      end
    end
  end
end
