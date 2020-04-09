# frozen_string_literal: true

require "pakyow/support/extension"

module Pakyow
  class Application
    module Behavior
      # Lets an application to be rescued from errors encountered when running. Once rescued,
      # the application triggers a 500 response with the error that caused it to fail.
      #
      module Rescuing
        extend Support::Extension

        apply_extension do
          events :rescue
        end

        common_methods do
          # Error the application was rescued from.
          #
          def error
            defined?(@error) ? @error : self.class.error
          end
          alias rescued error

          # Returns true if the application has been rescued.
          #
          def rescued?
            if is_a?(Application)
              self.class.rescued? || (instance_variable_defined?(:@error) && !!@error)
            else
              instance_variable_defined?(:@error) && !!@error
            end
          end

          # Enters rescue mode after reporting the error.
          #
          def rescue!(error)
            @error = error

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
            application_connection = isolated(:Connection).new(self, connection)
            application_connection.error = rescued
            application_connection.trigger 500
          end
        end
      end
    end
  end
end
