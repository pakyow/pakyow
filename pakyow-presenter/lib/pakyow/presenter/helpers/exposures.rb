# frozen_string_literal: true

require "pakyow/support/core_refinements/array/ensurable"

module Pakyow
  module Presenter
    module Helpers
      module Exposures
        using Support::Refinements::Array::Ensurable

        # Expose a value by name.
        #
        def expose(name, default_value = default_omitted = true, options = {}, &block)
          if channel = options[:for]
            name = [name].concat(Array.ensure(channel)).join(":").to_sym
          end

          if default_omitted
            super(name, &block)
          else
            super(name, default_value, &block)
          end
        end
      end
    end
  end
end
