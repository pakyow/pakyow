# frozen_string_literal: true

require "pakyow/support/deep_dup"

module Pakyow
  module Routing
    module Behavior
      module ErrorHandling
        using Support::DeepDup

        def self.included(base)
          base.include API
          base.extend ClassAPI
          base.prepend Initializer

          base.instance_variable_set(:@handlers, {})
          base.instance_variable_set(:@exceptions, {})
        end

        module Initializer
          def initialize(*)
            @handlers = self.class.handlers.deep_dup
            @exceptions = self.class.exceptions.deep_dup

            super
          end

          # Calls the handler for a particular http status code.
          #
          def trigger(name_or_code)
            code = Rack::Utils.status_code(name_or_code)
            response.status = code
            trigger_for_code(code)
          end

          def handle_error(error)
            request.error = error

            if code_and_handler = exception_for_class(error.class)
              code, handler   = code_and_handler
              response.status = code
              instance_exec(&handler); halt
            end
          end

          protected

          def trigger_for_code(code)
            return unless handler = handler_for_code(code)
            instance_exec(&handler); throw :halt, response
          end

          def handler_for_code(code)
            @handlers[code]
          end

          def exception_for_class(klass)
            @exceptions[klass]
          end
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
              @exceptions[name_exception_or_code] = [Rack::Utils.status_code(as), block]
            else
              @handlers[Rack::Utils.status_code(name_exception_or_code)] = block
            end
          end
        end

        module ClassAPI
          attr_reader :handlers, :exceptions

          def self.extended(base)
            base.extend(API)
          end

          def inherited(subclass)
            super
            subclass.instance_variable_set(:@handlers, @handlers.deep_dup)
            subclass.instance_variable_set(:@exceptions, @exceptions.deep_dup)
          end
        end
      end
    end
  end
end
