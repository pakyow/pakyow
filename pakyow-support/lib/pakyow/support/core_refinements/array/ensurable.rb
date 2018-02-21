# frozen_string_literal: true

module Pakyow
  module Support
    module Refinements
      module Array
        module Ensurable
          refine ::Array.singleton_class do
            def ensure(object)
              if object.respond_to?(:to_ary)
                object.to_ary
              else
                [object]
              end
            end
          end
        end
      end
    end
  end
end
