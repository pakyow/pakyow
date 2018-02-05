# frozen_string_literal: true

require "pakyow/commands/helpers"

module Pakyow
  # @api private
  module Commands
    # @api private
    class Generate
      include Helpers

      def initialize(generator, app: nil, args: [])
        @generator, @app, @args = generator, app, args
      end

      def run
        require "./config/environment"
        Pakyow.setup

        if app_instance = find_app(@app)
          @args.unshift(app_instance)
          require "pakyow/generators/#{@generator}/#{@generator}_generator"
          generator = Pakyow::Generators.const_get(Support.inflector.camelize(@generator))
          generator.start(@args)
        end
      rescue LoadError
        Pakyow.logger.error "Could not find generator named `#{@generator}'"
      end
    end
  end
end
