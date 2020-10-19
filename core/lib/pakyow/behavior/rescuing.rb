# frozen_string_literal: true

require "pakyow/support/extension"

module Pakyow
  module Behavior
    # Lets the environment to be rescued from errors encountered when running. Once rescued,
    # the environment triggers a 500 response with the error that caused it to fail.
    #
    module Rescuing
      extend Support::Extension

      apply_extension do
        events :rescue
      end

      class_methods do
        # Error the environment was rescued from.
        #
        attr_reader :error
        alias_method :rescued, :error

        # Returns true if the environment has been rescued.
        #
        def rescued?
          defined?(@error) && !!@error
        end

        # Enters rescue mode after reporting the error.
        #
        def rescue!(error)
          @error = error

          performing :rescue, error: error do
            Pakyow.houston(error)

            include Rescued
          end
        end
      end

      # Installs the `rescued` action on the including object.
      #
      module Rescued
        extend Support::Extension

        apply_extension do
          action :rescued, before: :all do |connection|
            connection.error = rescued
            connection.trigger 500
          end
        end
      end
    end
  end
end
