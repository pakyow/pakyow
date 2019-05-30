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
              parameters.any? { |(parameter_type, parameter_name)|
                (parameter_type == :key || parameter_type == :keyreq) && parameter_name == argument_name
              }
            end
          end
        end
      end
    end
  end
end
