# frozen_string_literal: true

module Pakyow
  module Routing
    module Helpers
      module Exposures
        # Expose a value by name.
        #
        def expose(name, default_value = default_omitted = true, &block)
          value = if block
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
