# frozen_string_literal: true

require "pakyow/support/deprecation"
require "pakyow/support/deprecator/reporters/null"


module Pakyow
  module Support
    # Gathers and reports deprecations through a reporter.
    #
    # A reporter can be any object that responds to `report`. Pakyow includes three reporters:
    #
    #   * {Deprecator::Reporters::Log}
    #   * {Deprecator::Reporters::Null}
    #   * {Deprecator::Reporters::Warn}
    #
    # @example
    #   deprecator = Pakyow::Support::Deprecator.new(
    #     reporter: Pakyow::Support::Deprecator::Reporters::Log(
    #       logger: Pakyow.logger
    #     )
    #   )
    #
    #   deprecator.deprecated :foo, solution: "use `bar'"
    #   => [deprecation] `foo' is deprecated; solution: use `bar'
    #
    # = Creating a reporter
    #
    # Reporters must respond to `report`. The deprecation object is fetched by yielding. This allows
    # the deprecation to be constructed lazily when/if the reporter needs the deprecation object.
    #
    # @example
    #
    #   class CustomReporter
    #     def report
    #       deprecation = yield
    #       # do something with the deprecation
    #     end
    #   end
    #
    class Deprecator
      def initialize(reporter:)
        @reporter = reporter
      end

      # Reports a deprecation through the reporter.
      #
      # @see Pakyow::Support::Deprecation
      #
      # @example
      #   deprecator = Pakyow::Support::Deprecator.new(
      #     Pakyow::Support::Deprecator::Reporters::Log(logger: Pakyow.logger)
      #   )
      #
      #   deprecator.deprecated Foo, :bar, solution: "use `baz'"
      #   => [deprecation] `Foo::bar' is deprecated; solution: use `baz'
      #
      #   deprecator.deprecated Foo.new, :bar, solution: "use `baz'"
      #   => [deprecation] `Foo#bar' is deprecated; solution: use `baz'
      #
      #   deprecator.deprecated "`foo.rb'", solution: "rename to `bar.rb'"
      #   => [deprecation] `foo.rb' is deprecated; solution: rename to `baz.rb'
      #
      def deprecated(*targets, solution:)
        reporter.report do
          Deprecation.new(*targets, solution: solution)
        end
      end

      # Ignores deprecations reported for the given block.
      #
      # @example
      #   deprecator = Pakyow::Support::Deprecator.new(
      #     Pakyow::Support::Deprecator::Reporters::Log(logger: Pakyow.logger)
      #   )
      #
      #   deprecator.ignore do
      #     deprecator.deprecated Foo.new, :bar, "use `baz'"
      #   end
      #
      def ignore
        replace(Reporters::Null); yield
      ensure
        replace(nil)
      end

      private def reporter
        Thread.current[thread_local_key] || @reporter
      end

      private def replace(reporter)
        Thread.current[thread_local_key] = reporter
      end

      private def thread_local_key
        @thread_local_key ||= :"pakyow_deprecator_#{object_id}_reporter"
      end

      class << self
        # Returns the global deprecator singleton. The global deprecator is setup to issue warnings
        # about deprecations. Use the global instance to report deprecations without making
        # assumptions about the broader environment.
        #
        # @example
        #   Pakyow::Support::Deprecator.global.deprecated :foo, solution: "use `bar'"
        #   => warning: [deprecation] `foo' is deprecated; solution: use `bar'
        #
        # = Forwarding
        #
        # Other deprecators can take over the role of reporting from the global deprecator. This is
        # how the Pakyow Environment takes over deprecation reporting in context of a project.
        #
        # @example
        #   Pakyow::Support::Deprecator.global >> Pakyow::Support::Deprecator::Reporters::Null
        #   Pakyow::Support::Deprecator.global.deprecated :foo, solution: "use `bar'"
        #
        def global
          unless defined?(@global)
            require "logger"
            require "pakyow/support/deprecator/global"
            require "pakyow/support/deprecator/reporters/warn"
            @global = Global.new(reporter: Reporters::Warn)
          end

          @global
        end
      end
    end
  end
end
