# frozen_string_literal: true

require "pakyow/commands/helpers"

module Pakyow
  # @api private
  module Commands
    # @api private
    class Rake
      include Helpers

      def initialize(task, app: nil, args: [], env: nil)
        @task, @app, @args = task, app, args

        @env = if env.nil? || env.empty?
          ENV["RACK_ENV"]
        else
          env
        end.to_s
      end

      def run
        require "./config/environment"
        Pakyow.setup(env: @env)
        Pakyow.load_tasks

        task = ::Rake.application[@task]

        if task.arg_names.include?(:app) && app_instance = find_app(@app)
          @args.unshift(app_instance)
        elsif options.key?(:app)
          Pakyow.logger.warn "Task does not run in context of an app; ignoring --app #{@app}"
        end

        task.invoke(*@args)
      end
    end
  end
end
