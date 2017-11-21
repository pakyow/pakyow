# frozen_string_literal: true

module Pakyow
  # @api private
  module Commands
    # @api private
    class Console
      def initialize(env: nil)
        @env = env.to_s
      end

      def run
        require "./config/environment"
        Pakyow.setup(env: @env)
        ARGV.clear

        require "irb"
        Pakyow.config.console.object.start
      end
    end
  end
end
