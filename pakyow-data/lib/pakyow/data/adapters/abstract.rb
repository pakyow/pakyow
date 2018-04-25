# frozen_string_literal: true

module Pakyow
  module Data
    module Adapters
      class Abstract
        def initialize(opts)
          @opts = opts
        end

        def dataset_for_source(_source)
          raise "dataset_for_source is not implemented on #{self}"
        end

        def connected?
          false
        end

        def migratable?
          false
        end

        module DatasetMethods
          def each(_dataset)
            raise "each is not implemented on #{self}"
          end

          def to_a(_dataset)
            raise "to_a is not implemented on #{self}"
          end

          def one(_dataset)
            raise "one is not implemented on #{self}"
          end
        end
      end
    end
  end
end
