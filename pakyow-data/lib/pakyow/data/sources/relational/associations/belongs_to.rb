# frozen_string_literal: true

require "pakyow/data/sources/relational/association"

module Pakyow
  module Data
    module Sources
      class Relational
        module Associations
          class BelongsTo < Association
            def type
              :belongs
            end

            def specific_type
              :belongs_to
            end

            def result_type
              :one
            end

            def foreign_key_field
              :"#{@name}_#{@associated_source.primary_key_field}"
            end

            def foreign_key_type
              @associated_source.primary_key_type
            end

            def query_field
              foreign_key_field
            end

            def associated_query_field
              @associated_source.primary_key_field
            end

            def dependents?
              false
            end
          end
        end
      end
    end
  end
end
