# frozen_string_literal: true

require "pakyow/support/deep_dup"
require "pakyow/support/inflector"

module Pakyow
  module Data
    class Command
      using Support::DeepDup

      def initialize(name, block:, source:, provides_dataset:, performs_update:)
        @name, @block, @source, @provides_dataset, @performs_update = name, block, source, provides_dataset, performs_update
      end

      def call(values = nil)
        if values
          # Enforce required attributes.
          #
          @source.class.attributes.each do |attribute_name, attribute|
            if attribute.meta[:required]
              if @name == :create && !values.include?(attribute_name)
                raise NotNullViolation.new("Expected a value for #{attribute_name}")
              end

              if values.include?(attribute_name) && values[attribute_name].nil?
                raise NotNullViolation.new("Expected a value for #{attribute_name}")
              end
            end
          end

          final_values = values.each_with_object({}) { |(key, value), values_hash|
            if attribute = @source.class.attributes[key]
              values_hash[key] = attribute[value]
            elsif @source.class.associations.values.flatten.find { |association| association[:access_name] == key }
              values_hash[key] = value
            end
          }

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

        original_dataset = if @performs_update
          # Hold on to the original values so we can update them locally.
          @source.dup.to_a
        else
          nil
        end

        unless @provides_dataset || @performs_update
          # Cache the result prior to running the command.
          @source.to_a
        end

        command_result = @source.instance_exec(final_values, &@block)

        if @performs_update
          # For updates, we fetch the values prior to performing the update and
          # return a source containing locally updated values. This lets us see
          # the original values but prevents us from fetching twice.

          @source.container.source_instance(@source.class.__class_name.name).tap do |updated_source|
            updated_source.__setobj__(
              @source.container.connection.adapter.result_for_attribute_value(
                @source.class.primary_key_field, command_result, updated_source
              )
            )

            updated_source.instance_variable_set(:@results, original_dataset.map { |original_object|
              original_object.class.new(original_object.values.merge(final_values))
            })

            updated_source.instance_variable_set(:@original_results, original_dataset)
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
