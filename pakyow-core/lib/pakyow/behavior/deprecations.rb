# frozen_string_literal: true

require "pakyow/support/deprecator"
require "pakyow/support/inflector"

module Pakyow
  module Behavior
    # Provides an environment-level deprecator for reporting deprecations within a project, plugin,
    # or framework. Guarantees that a deprecator will be available, even if misconfigured.
    #
    # Deprecations reported to `Pakyow::Support::Deprecator.global` will be forwarded here. This
    # allows libraries to safely report deprecations even if they happen to be used outside the
    # context of the Pakyow environnment.
    #
    # To ignore deprecation notices configure the `null` reporter:
    #
    #   config.deprecator.reporter = :null
    #
    module Deprecations
      extend Support::Extension

      class_methods do
        # Returns the environment deprecator, where all runtime deprecations should be reported.
        #
        def deprecator
          @deprecator ||= setup_deprecator(config.deprecator.reporter)
        end

        # Reports a deprecation to the environment deprecator.
        #
        def deprecated(*args)
          deprecator.deprecated(*args)
        end

        private def setup_deprecator(deprecator)
          @deprecator = if (reporter = setup_deprecation_reporter(deprecator))
            Support::Deprecator.new(reporter: reporter).tap do |instance|
              Support::Deprecator.global >> instance
            end
          else
            Support::Deprecator.global
          end
        end

        private def setup_deprecation_reporter(deprecator)
          case deprecator
          when String, Symbol
            setup_deprecation_reporter_for_string(
              deprecator
            )
          when Class
            setup_deprecation_reporter_for_class(
              deprecator
            )
          else
            deprecator
          end
        end

        private def setup_deprecation_reporter_for_string(deprecator)
          require_deprecation_reporter(deprecator)

          setup_deprecation_reporter_for_class(
            deprecation_reporter_class(deprecator)
          )
        end

        private def setup_deprecation_reporter_for_class(deprecator)
          if deprecator.respond_to?(:default)
            deprecator.default
          else
            deprecator
          end
        end

        private def require_deprecation_reporter(deprecator)
          require "pakyow/support/deprecator/reporters/#{deprecator}"
        end

        private def deprecation_reporter_class(deprecator)
          Support::Deprecator::Reporters.const_get(
            Support.inflector.classify(
              deprecator
            )
          )
        end

        private def fallback_deprecation_reporter
          setup_deprecation_reporter_for_string("log")
        end
      end

      apply_extension do
        configurable :deprecator do
          setting :reporter, :log

          defaults :test do
            setting :reporter, :warn
          end

          defaults :production do
            setting :reporter, :null
          end
        end

        after "setup" do
          # Ensure that the deprecator is defined.
          #
          deprecator
        end
      end
    end
  end
end
