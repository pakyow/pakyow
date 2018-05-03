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
          final_values = values.to_h.deep_dup

          if timestamp_fields = @source.class.timestamp_fields
            if @name == :create
              timestamp_fields.values.each do |timestamp_field|
                final_values[timestamp_field] = Time.now
              end
            elsif timestamp_field = timestamp_fields[@name]
              final_values[timestamp_field] = Time.now
            end
          end

          if @name == :create
            # Set default values.
            #
            @source.class.attributes.each do |attribute_name, attribute|
              if !final_values.include?(attribute_name) && default = attribute.meta[:default]
                final_values[attribute_name] = if default.is_a?(Proc)
                  default.call
                else
                  default
                end
              end
            end
          end

          # Enforce required attributes.
          #
          @source.class.attributes.each do |attribute_name, attribute|
            if attribute.meta[:required]
              if @name == :create && !final_values.include?(attribute_name)
                raise NotNullViolation.new("Expected a value for #{attribute_name}")
              end

              if final_values.include?(attribute_name) && final_values[attribute_name].nil?
                raise NotNullViolation.new("Expected a value for #{attribute_name}")
              end
            end
          end

          @source.class.associations.values.flatten.each do |association|
            inflector_call = case association[:access_type]
            when :one then :singularize
            when :many then :pluralize
            end

            key = Support.inflector.public_send(
              inflector_call,
              association[:source_name]
            ).to_sym

            if final_values.key?(key)
              final_values[association[:column_name]] = final_values.delete(key)[@source.class.primary_key_field]
            end
          end
        end

        unless @provides_dataset || @provides_ids
          @source.to_a
        end

        command_result = @source.instance_exec(final_values, &@block)

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
