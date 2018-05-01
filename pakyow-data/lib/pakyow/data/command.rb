# frozen_string_literal: true

require "pakyow/support/deep_dup"

module Pakyow
  module Data
    class Command
      using Support::DeepDup

      def initialize(name, block:, source:, provides_dataset:, provides_ids:)
        @name, @block, @source, @provides_dataset, @provides_ids = name, block, source, provides_dataset, provides_ids
      end

      def call(values = nil)
        if values
          if timestamp_fields = @source.class.timestamp_fields
            if @name == :create
              timestamp_fields.values.each do |timestamp_field|
                values[timestamp_field] = Time.now
              end
            elsif timestamp_field = timestamp_fields[@name]
              values[timestamp_field] = Time.now
            end
          end

          if values.is_a?(Support::IndifferentHash)
            values = values.__getobj__
          end

          values = values.deep_dup

          @source.class.associations.values.flatten.each do |association|
            inflector_call = case association[:access_type]
            when :one then :singularize
            when :many then :pluralize
            end

            key = Support.inflector.public_send(
              inflector_call,
              association[:source_name]
            ).to_sym

            if values.key?(key)
              values[association[:column_name]] = values.delete(key)[@source.class.primary_key_field]
            end
          end
        end

        unless @provides_dataset || @provides_ids
          @source.to_a
        end

        command_result = @source.instance_exec(values, &@block)

        if @provides_ids
          @source.container.source_instance(@source.class.__class_name.name).tap do |updated_source|
            updated_source.__setobj__(
              @source.container.connection.adapter.result_for_attribute_value(
                @source.class.primary_key_field, command_result, updated_source
              )
            )
          end
        elsif @provides_dataset
          @source.dup.tap { |source|
            source.__setobj__(command_result)
          }
        else
          @source
        end
      end
    end
  end
end
