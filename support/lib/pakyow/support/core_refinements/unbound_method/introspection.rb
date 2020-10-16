# frozen_string_literal: true

module Pakyow
  module Support
    module Refinements
      module UnboundMethod
        module Introspection
          refine ::UnboundMethod do
            # Returns true if +argument_name+ is defined as a keyword argument.
            #
            def keyword_argument?(argument_name)
              parameters.any? { |(parameter_type, parameter_name)|
                (parameter_type == :key || parameter_type == :keyreq) && parameter_name == argument_name
              }
            end

            # Returns true if this method accepts a keyword argument.
            #
            def keyword_arguments?
              parameters.any? { |(parameter_type, _)|
                parameter_type == :key || parameter_type == :keyreq || parameter_type == :keyrest
              }
            end

            # Returns true if this method accepts one or more arguments.
            #
            def argument_list?
              parameters.any? { |(parameter_type, _)|
                parameter_type == :req || parameter_type == :opt || parameter_type == :rest
              }
            end
          end
        end
      end
    end
  end
end
