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
              self.class.rescued? || (defined?(@rescued) && !!@rescued)
            else
              defined?(@rescued) && !!@rescued
            end
          end

          # Enters rescue mode after logging the error.
          #
          private def rescue!(error)
            @rescued = error

            performing :rescue do
              Pakyow.logger.error(error)

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
            message = <<~ERROR
              #{self.class} failed to initialize.

              #{rescued.message}
              #{rescued.backtrace.join("\n")}
            ERROR

            connection.status = 500
            connection.body = StringIO.new(message)
            connection.halt
          end
        end
      end
    end
  end
end
