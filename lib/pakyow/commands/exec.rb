# frozen_string_literal: true

module Pakyow
  # @api private
  module Commands
    # @api private
    class ExecTask
      def initialize(task, app: nil, args: [], env: nil)
        @task, @app, @args, @env = task, app, args, env.to_s
      end

      def run
        require "./config/environment"
        Pakyow.setup(env: @env)
        Pakyow.load_tasks

        task = Rake.application[@task]

        if task.arg_names.include?(:app)
          app_instance = if @app
            Pakyow.find_app(@app) || (Pakyow.logger.error("Could not find an app named `#{@app}'"); exit)
          elsif Pakyow.apps.count == 1
            Pakyow.apps.first
          else
            Pakyow.logger.error "Multiple apps are present; please provide an app name (via the --app option)"
            exit
          end

          @args.unshift(app_instance)
        else
          if options.key?(:app)
            Pakyow.logger.warn "Task does not run in context of an app; ignoring --app #{@app}"
          end
        end

        task.invoke(*@args)
      end
    end
  end
end
