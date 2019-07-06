# frozen_string_literal: true

require "forwardable"

require "pakyow/support/inflector"

require "pakyow/data/sources/relational/association"

module Pakyow
  module Data
    module Sources
      class Relational
        module Associations
          # @api private
          class Through
            attr_reader :joining_source_name, :joining_source

            # @api private
            attr_writer :joining_source

            extend Forwardable
            def_delegators :@association, :associated_name, :associated_query_field, :associated_source=, :associated_source,
                           :associated_source_name, :dependent, :dependents?, :name, :query, :query_field, :result_type,
                           :source, :specific_type

            def initialize(association, joining_source_name:)
              @association, @joining_source_name = association, Support.inflector.pluralize(joining_source_name).to_sym

              @internal = false
            end

            def type
              :through
            end

            def dependent_source_names
              [@association.associated_source_name, @joining_source_name]
            end

            def left_name
              Support.inflector.singularize(@association.name).to_sym
            end

            def left_foreign_key_field
              :"#{left_name}_#{@association.associated_source.primary_key_field}"
            end

            def right_name
              Support.inflector.singularize(@association.associated_name).to_sym
            end

            def right_foreign_key_field
              :"#{right_name}_#{@association.source.primary_key_field}"
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
end
