# frozen_string_literal: true

require "pakyow/support/inflector"

module Pakyow
  module Data
    module Sources
      class Relational
        class Association
          attr_reader :name, :query, :source, :associated_source_name, :associated_source

          # @api private
          attr_writer :associated_source

          def initialize(name:, query:, source:, associated_source_name:)
            @name = case result_type
            when :one
              Support.inflector.singularize(name).to_sym
            when :many
              Support.inflector.pluralize(name).to_sym
            end

            @query, @source, @associated_source_name = query, source, Support.inflector.pluralize(associated_source_name).to_sym

            @internal = false
          end

          def dependent_source_names
            [@associated_source_name]
          end

          def internal?
            @internal == true
          end

          def internal!
            @internal = true
          end
        end
      end
    end
  end
end
