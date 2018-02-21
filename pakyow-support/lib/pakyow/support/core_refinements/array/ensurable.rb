# frozen_string_literal: true

module Pakyow
  module Support
    module Refinements
      module Array
        module Ensurable
          refine ::Array.singleton_class do
            # Ensures that +object+ is an array, converting it if necessary. This
            # was added to safely wrap hashes, because +Array(hash)+ converts
            # into an array of key/value pairs.
            #
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
