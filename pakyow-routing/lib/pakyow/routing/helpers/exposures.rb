# frozen_string_literal: true

module Pakyow
  module Routing
    module Helpers
      module Exposures
        # Expose a value by name, if the value is not already set.
        #
        def expose(name, default_value = default_omitted = true, &block)
          unless @connection.set?(name)
            set_exposure(name, default_value, default_omitted, &block)
          end
        end

        # Force expose a value by name, overriding any existing value.
        #
        def expose!(name, default_value = default_omitted = true, &block)
          set_exposure(name, default_value, default_omitted, &block)
        end

        # @api private
        def set_exposure(name, default_value, default_omitted)
          value = if block_given?
            yield
          elsif default_omitted
            __send__(name)
          end

          unless default_omitted
            value ||= default_value
          end

          @connection.set(name, value)
        end
      end
    end
  end
end
