# frozen_string_literal: true

require "pakyow/support/extension"

module Pakyow
  module Behavior
    # Lets an app to be rescued from errors encountered during boot. Once rescued,
    # an app returns a 500 response with the error that caused it to fail.
    #
    module Rescuing
      extend Support::Extension

      # Returns true if the app has been rescued.
      #
      def rescued?
        @rescued == true
      end

      private

      # Enters rescue mode after logging the error.
      #
      def rescue!(error)
        @rescued = true

        performing :rescue do
          message = <<~ERROR
            #{self.class} failed to initialize.

            #{error.to_s}
            #{error.backtrace.join("\n")}
          ERROR

          Pakyow.logger.error message

          # Override call to always return an errored response.
          #
          define_singleton_method :call do |_|
            error_500(message)
          end
        end
      end
    end
  end
end
