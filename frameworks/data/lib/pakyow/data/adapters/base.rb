# frozen_string_literal: true

module Pakyow
  module Data
    module Adapters
      class Base
        def initialize(opts, logger: nil)
          @opts, @logger = opts, logger
        end

        def dataset_for_source(_source)
          raise "dataset_for_source is not implemented on #{self}"
        end

        def result_for_attribute_value(_attribute, _value, _source)
          raise "result_for_attribute_value is not implemented on #{self}"
        end

        def transaction
          raise "transactions are not supported by #{self}"
        end

        def connected?
          false
        end

        def migratable?
          false
        end

        class << self
          def types_for_adapter(_adapter)
          end
        end

        module SourceExtension
        end

        module Commands
        end

        module DatasetMethods
          def to_a(_dataset)
            raise "to_a is not implemented on #{self}"
          end

          def one(_dataset)
            raise "one is not implemented on #{self}"
          end

          def count(_dataset)
            raise "count is not implemented on #{self}"
          end
        end
      end
    end
  end
end
