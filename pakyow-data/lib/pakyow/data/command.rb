# frozen_string_literal: true

require "pakyow/support/deep_dup"
require "pakyow/support/inflector"

module Pakyow
  module Data
    class Command
      using Support::DeepDup

      def initialize(name, block:, source:, provides_dataset:, performs_create:, performs_update:, performs_delete:)
        @name, @block, @source, @provides_dataset, @performs_create, @performs_update, @performs_delete = name, block, source, provides_dataset, performs_create, performs_update, performs_delete
      end

      def call(values = nil)
        if values
          # Enforce required attributes.
          #
          @source.class.attributes.each do |attribute_name, attribute|
            if attribute.meta[:required]
              if @performs_create && !values.include?(attribute_name)
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
            if @performs_create
              timestamp_fields.values.each do |timestamp_field|
                final_values[timestamp_field] = Time.now
              end
            elsif timestamp_field = timestamp_fields[@name]
              final_values[timestamp_field] = Time.now
            end
          end

          if @performs_create
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
            if final_values.key?(association[:access_name])
              final_values[association[:column_name]] = final_values.delete(association[:access_name])[@source.class.primary_key_field]
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

        @source.transaction do
          if @performs_delete
            @source.class.associations.values.flatten.select { |association|
              association.key?(:dependent)
            }.each do |association|
              dependent_data = @source.container.source_instance(association[:source_name]).send(
                :"by_#{association[:associated_column_name]}", @source.container.connection.adapter.restrict_to_attribute(
                  @source.class.primary_key_field, @source
                )
              )

              case association[:dependent]
              when :delete
                dependent_data.delete
              when :nullify
                dependent_data.update(association[:associated_column_name] => nil)
              when :raise
                dependent_count = dependent_data.count
                if dependent_count > 0
                  dependent_name = if dependent_count > 1
                    Support.inflector.pluralize(association[:source_name])
                  else
                    Support.inflector.singularize(association[:source_name])
                  end

                  raise ConstraintViolation, "Cannot delete #{@source.class.__object_name.name} because of #{dependent_count} dependent #{dependent_name}"
                end
              end
            end
          end

          if @performs_create || @performs_update
            @source.class.associations[:belongs_to].flat_map { |belongs_to_association|
              @source.container.source_instance(belongs_to_association[:source_name]).class.associations[:has_one].select { |has_one_association|
                has_one_association[:associated_column_name] == belongs_to_association[:column_name]
              }
            }.each do |association|
              value = final_values.dig(
                association[:associated_access_name], association[:column_name]
              ) || final_values.dig(association[:associated_column_name])

              if value
                @source.container.source_instance(@source.class.__object_name.name).tap do |impacted_source|
                  impacted_source.__setobj__(
                    @source.container.connection.adapter.result_for_attribute_value(
                      association[:associated_column_name], value, impacted_source
                    )
                  )

                  impacted_source.update(association[:associated_column_name] => nil)
                end
              end
            end
          end

          command_result = @source.instance_exec(final_values, &@block)

          if @performs_update
            # For updates, we fetch the values prior to performing the update and
            # return a source containing locally updated values. This lets us see
            # the original values but prevents us from fetching twice.

            @source.container.source_instance(@source.class.__object_name.name).tap do |updated_source|
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
end
