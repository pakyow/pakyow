# frozen_string_literal: true

require "pakyow/support/inflector"

require "pakyow/data/sources/relational/association"

module Pakyow
  module Data
    module Sources
      class Relational
        module Associations
          class HasOne < Association
            attr_reader :associated_name, :dependent

            def initialize(as:, dependent:, **common_args)
              super(**common_args)

              @associated_name = Support.inflector.singularize(as).to_sym
              @dependent = dependent
            end

            def type
              :has
            end

            def specific_type
              :has_one
            end

            def result_type
              :one
            end

            def foreign_key_field
              associated_query_field
            end

            def query_field
              @source.primary_key_field
            end

            def associated_query_field
              :"#{@associated_name}_#{@source.primary_key_field}"
            end

            def dependents?
              true
            end
          end
        end
      end
    end
  end
end
