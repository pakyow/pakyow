# frozen_string_literal: true

require "pakyow/support/class_state"
require "pakyow/support/deep_dup"
require "pakyow/support/extension"

module Pakyow
  module Routing
    module Behavior
      module ErrorHandling
        extend Support::Extension

        apply_extension do
          class_state :handlers, default: {}, inheritable: true
          class_state :exceptions, default: {}, inheritable: true

          events :error

          include API
          extend API
        end

        prepend_methods do
          using Support::DeepDup

          def initialize(*)
            @handlers = self.class.handlers.deep_dup
            @exceptions = self.class.exceptions.deep_dup

            super
          end
        end

        # Calls the handler for a particular http status code.
        #
        def trigger(name_or_code)
          code = Connection.status_code(name_or_code)
          connection.status = code
          trigger_for_code(code)
        end

        def handle_error(error)
          connection.error = error

          performing :error do
            connection.status = 500
            catch :halt do
              call_handlers_with_args(
                exceptions_for_class(error.class) || handlers_for_code(500),
                error
              )
            end
          end

          halt
        end

        private

        def call_handlers_with_args(handlers, *args)
          handlers.to_a.reverse.each do |status_code, handler|
            catch :reject do
              connection.status = status_code

              if handler
                instance_exec(*args, &handler)
              end

              halt
            end
          end
        end

        def trigger_for_code(code)
          call_handlers_with_args(handlers_for_code(code)); halt
        end

        def handlers_for_code(code)
          @handlers[code]
        end

        def exceptions_for_class(klass)
          @exceptions[klass]
        end

        module API
          # Registers an error handler used within a controller or request lifecycle.
          #
          # @example Defining for a controller:
          #   Pakyow::App.controller do
          #     handle 500 do
          #       # build and send a response for `request.error`
          #     end
          #
          #     default do
          #       # do something that might cause an error
          #     end
          #   end
          #
          # @example Defining for a request lifecycle:
          #   Pakyow::App.controller do
          #     default do
          #       handle 500 do
          #         # build and send a response for `request.error`
          #       end
          #
          #       # do something that might cause an error
          #     end
          #   end
          #
          # @example Handling by status code:
          #   handle 500 do
          #     # build and send a response
          #   end
          #
          #   default do
          #     trigger 500
          #   end
          #
          # @example Handling by status name:
          #   handle :forbidden do
          #     # build and send a response
          #   end
          #
          #   default do
          #     trigger 403 # or, `trigger :forbidden`
          #   end
          #
          # @example Handling an exception:
          #   handle Sequel::NoMatchingRow, as: 404 do
          #     # build and send a response
          #   end
          #
          #   default do
          #     raise Sequel::NoMatchingRow
          #   end
          #
          def handle(name_exception_or_code, as: nil, &block)
            if name_exception_or_code.is_a?(Class) && name_exception_or_code.ancestors.include?(Exception)
              raise ArgumentError, "status code is required" if as.nil?
              (@exceptions[name_exception_or_code] ||= []) << [Connection.status_code(as), block]
            else
              status_code = Connection.status_code(name_exception_or_code)
              (@handlers[status_code] ||= []) << [as || status_code, block]
            end
          end
        end
      end
    end
  end
end
