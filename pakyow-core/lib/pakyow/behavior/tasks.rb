# frozen_string_literal: true

require "pakyow/support/extension"

module Pakyow
  module Behavior
    module Tasks
      extend Support::Extension

      apply_extension do
        class_state :tasks, default: []

        # @api private
        def load_tasks
          require "pakyow/task"
          tasks.clear

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
