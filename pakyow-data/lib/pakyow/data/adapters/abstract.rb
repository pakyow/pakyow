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

        def migratable?
          false
        end
      end
    end
  end
end
