# frozen_string_literal: true

module Pakyow
  module Data
    module Adapters
      class Sql
        module DatasetMethods
          def to_a(dataset)
            dataset.all
          rescue Sequel::Error => error
            raise QueryError.build(error)
          end

          def one(dataset)
            dataset.first
          rescue Sequel::Error => error
            raise QueryError.build(error)
          end

          def count(dataset)
            dataset.count
          rescue Sequel::Error => error
            raise QueryError.build(error)
          end
        end
      end
    end
  end
end
