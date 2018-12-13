# frozen_string_literal: true

module Pakyow
  module Data
    module Adapters
      class Sql
        module DatasetMethods
          def to_a(dataset)
            dataset.qualify.all
          rescue Sequel::Error => error
            raise QueryError.build(error)
          end

          def one(dataset)
            dataset.qualify.first
          rescue Sequel::Error => error
            raise QueryError.build(error)
          end

          def count(dataset)
            dataset.qualify.count
          rescue Sequel::Error => error
            raise QueryError.build(error)
          end
        end
      end
    end
  end
end
