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

        common_methods do
          # Error the app was rescued from.
          #
          def rescued
            defined?(@rescued) ? @rescued : self.class.rescued
          end

          # Returns true if the app has been rescued.
          #
          def rescued?
            if is_a?(Application)
              self.class.rescued? || (instance_variable_defined?(:@rescued) && !!@rescued)
            else
              instance_variable_defined?(:@rescued) && !!@rescued
            end
          end

          # Enters rescue mode after reporting the error.
          #
          def rescue!(error)
            @rescued = error

            performing :rescue, error: error do
              Pakyow.houston(error)

              if is_a?(Application)
                singleton_class.include Rescued
              else
                include Rescued
              end
            end
          end
        end

        module Rescued
          def call(connection)
            isolated(:Connection).new(self, connection).tap do |application_connection|
              application_connection.error = rescued
              application_connection.trigger 500
            end
          end
        end
      end
    end
  end
end
