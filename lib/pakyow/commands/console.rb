require "pakyow/commands/console_methods.rb"

module Pakyow
  module Commands
    class Console
      attr_reader :environment

      def initialize(environment: :development)
        @environment = environment
      end

      def run
        load_app
        Pakyow::App.stage(environment)
        require 'irb'
        ARGV.clear
        IRB::ExtendCommandBundle.include(ConsoleMethods)
        IRB.start
      end

      private

      def load_app
        $LOAD_PATH.unshift(Dir.pwd)
        require 'app/setup'
      end
    end
  end
end
