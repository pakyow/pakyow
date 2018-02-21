# frozen_string_literal: true

module Pakyow
  module Support
    module Refinements
      module Method
        module Introspection
          refine ::Method do
            # Returns true if +argument_name+ is defined as a keyword argument.
            #
            def keyword_argument?(argument_name)
              parameters.each do |(parameter_type, parameter_name)|
                return true if parameter_type == :key && parameter_name == argument_name
              end

              false
            end
          end
        end
      end
    end
  end
end
