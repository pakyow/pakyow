# frozen_string_literal: true

require "pakyow/support/extension"

module Pakyow
  class Application
    module Behavior
      # Lets an app to be rescued from errors encountered during boot. Once rescued,
      # an app returns a 500 response with the error that caused it to fail.
      #
      module Rescuing
        extend Support::Extension

        # Error the app was rescued from.
        #
        attr_reader :rescued

        # Returns true if the app has been rescued.
        #
        def rescued?
          instance_variable_defined?(:@rescued) && !!@rescued
        end

        private

        # Enters rescue mode after logging the error.
        #
        def rescue!(error)
          @rescued = error

          performing :rescue do
            Pakyow.logger.error(error)

            message = <<~ERROR
              #{self.class} failed to initialize.

              #{error.message}
              #{error.backtrace.join("\n")}
            ERROR

            # Override call to always return an errored response.
            #
            define_singleton_method :call do |connection|
              connection.status = 500
              connection.body = StringIO.new(message)
              connection.halt
            end
          end
        end
      end
    end
  end
end
