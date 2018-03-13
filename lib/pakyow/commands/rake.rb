# frozen_string_literal: true

require "pakyow/commands/helpers"

module Pakyow
  # @api private
  module Commands
    # @api private
    class Rake
      include Helpers

      def initialize(task, **options)
        @task, @options = task, options
      end

      def run
        task = ::Rake.application[@task]

        args = task.arg_names.each_with_object([]) { |arg_name, args_arr|
          arg_name = arg_name.to_sym
          args_arr << if arg_name == :app
            find_app(@options[:app])
          else
            @options[arg_name]
          end
        }

        task.invoke(*args)
      end
    end
  end
end
