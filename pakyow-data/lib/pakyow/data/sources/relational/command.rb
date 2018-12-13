# frozen_string_literal: true

require "pakyow/support/deep_dup"
require "pakyow/support/inflector"
require "pakyow/support/core_refinements/array/ensurable"

module Pakyow
  module Data
    module Sources
      class Relational
        class Command
          using Support::DeepDup
          using Support::Refinements::Array::Ensurable

          def initialize(name, block:, source:, provides_dataset:, performs_create:, performs_update:, performs_delete:)
            @name, @block, @source, @provides_dataset, @performs_create, @performs_update, @performs_delete = name, block, source, provides_dataset, performs_create, performs_update, performs_delete
          end

          def call(values = {})
            future_associated_changes = []

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

              # Fail if unexpected values were passed.
              #
              values.keys.each do |key|
                unless @source.class.attributes.include?(key) || @source.class.association_for_access_name?(key)
                  raise UnknownAttribute.new("Unknown attribute #{key} for #{@source.class.__object_name.name}")
                end
              end

              # Coerce values into the appropriate type.
              #
              final_values = values.each_with_object({}) { |(key, value), values_hash|
                begin
                  if attribute = @source.class.attributes[key]
                    if value.is_a?(Proxy) || value.is_a?(Object)
                      raise TypeMismatch, "can't convert #{value} into #{attribute.meta[:mapping]}"
                    end

                    values_hash[key] = value.nil? ? value : attribute[value]
                  else
                    values_hash[key] = value
                  end
                rescue TypeError, Dry::Types::ConstraintError => error
                  raise TypeMismatch.build(error)
                end
              }

              # Update timestamp fields.
              #
              if timestamp_fields = @source.class.timestamp_fields
                if @performs_create
                  timestamp_fields.values.each do |timestamp_field|
                    final_values[timestamp_field] = Time.now
                  end
                # Don't update timestamps if we aren't also updating other values.
                #
                elsif values.any? && timestamp_field = timestamp_fields[@name]
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

              # Enforce constraints on association values passed by access name.
              #
              @source.class.associations.values.flatten.select { |association|
                final_values.key?(association[:access_name])
              }.each do |association|
                association_value = final_values[association[:access_name]]

                case association_value
                when Proxy
                  if association_value.source.class.__object_name.name == association[:source_name]
                    if association[:access_type] == :one && (association_value.count > 1 || (@performs_update && @source.count > 1))
                      raise ConstraintViolation, "Cannot associate multiple results as #{association[:access_name]}"
                    end
                  else
                    raise TypeMismatch, "Cannot associate #{association_value.source.class.__object_name.name} as #{association[:access_name]}"
                  end
                when Object
                  if association[:access_type] == :one
                    if association_value.originating_source
                      if association_value.originating_source.__object_name.name == association[:source_name]
                        case association[:type]
                        when :belongs_to
                          associated_column_name = association[:associated_column_name]
                          associated_column_value = association_value[association[:associated_column_name]]
                          associated_object_query = association[:source].instance.send(
                            :"by_#{association[:associated_column_name]}", associated_column_value
                          )
                        when :has_one
                          associated_column_name = association[:column_name]
                          associated_column_value = association_value[association[:column_name]]
                          associated_object_query = association[:source].instance.send(
                            :"by_#{association[:column_name]}", associated_column_value
                          )
                        end

                        if associated_object_query && associated_object_query.count == 0
                          raise ConstraintViolation, "Cannot find associated #{association[:access_name]} with #{associated_column_name} of #{associated_column_value}"
                        end
                      else
                        raise TypeMismatch, "Cannot associate an object from #{association_value.originating_source.__object_name.name} as #{association[:access_name]}"
                      end
                    else
                      raise TypeMismatch, "Cannot associate an object with an unknown source as #{association[:access_name]}"
                    end
                  else
                    raise TypeMismatch, "Cannot associate #{association_value.class} as #{association[:access_name]}"
                  end
                when Array
                  if association[:access_type] == :many
                    if association_value.find { |value| !value.is_a?(Object) }
                      raise TypeMismatch, "Cannot associate results as #{association[:access_name]} because at least one value is not a Pakyow::Data::Object"
                    else
                      if association_value.any? { |value| value.originating_source.nil? }
                        raise TypeMismatch, "Cannot associate an object with an unknown source as #{association[:access_name]}"
                      else
                        if association_value.find { |value| value.originating_source.__object_name.name != association[:source_name] }
                          raise TypeMismatch, "Cannot associate results as #{association[:access_name]} because at least one value did not originate from #{association[:source_name]}"
                        else
                          associated_column_value = association_value.map { |object| object[association[:column_name]] }
                          associated_object_query = association[:source].instance.send(
                            :"by_#{association[:column_name]}", associated_column_value
                          )

                          if associated_object_query.count != association_value.count
                            raise ConstraintViolation, "Cannot associate results as #{association[:access_name]} because at least one value could not be found"
                          end
                        end
                      end
                    end
                  else
                    raise ConstraintViolation, "Cannot associate multiple results as #{association[:access_name]}"
                  end
                when NilClass
                else
                  raise TypeMismatch, "Cannot associate #{association_value.class} as #{association[:access_name]}"
                end
              end

              # Enforce constraints for association values passed by column name.
              #
              @source.class.associations.values.flatten.select { |association|
                final_values.key?(association[:column_name]) && !final_values[association[:column_name]].nil?
              }.each do |association|
                associated_column_value = final_values[association[:column_name]]
                associated_object_query = association[:source].instance.send(
                  :"by_#{association[:associated_column_name]}", associated_column_value
                )

                if associated_object_query.count == 0
                  raise ConstraintViolation, "Cannot find associated #{association[:access_name]} with #{association[:associated_column_name]} of #{associated_column_value}"
                end
              end

              # Set values for associations passed by access name.
              #
              @source.class.associations.values.flatten.select { |association|
                final_values.key?(association[:access_name])
              }.each do |association|
                case association[:type]
                when :belongs_to
                  association_value = final_values.delete(association[:access_name])
                  final_values[association[:column_name]] = case association_value
                  when Proxy
                    if association_result = association_value.one
                      association_result[association[:associated_column_name]]
                    else
                      nil
                    end
                  when Object
                    association_value[association[:associated_column_name]]
                  when NilClass
                    nil
                  end
                when :has_many, :has_one
                  future_associated_changes << [association, final_values.delete(association[:access_name])]
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
                  dependent_values = @source.class.container.connection.adapter.restrict_to_attribute(
                    @source.class.primary_key_field, @source
                  )

                  # If objects are located in two different connections, fetch the raw values.
                  #
                  unless @source.class.container.connection == association[:source].container.connection
                    dependent_values = dependent_values.map { |dependent_value|
                      dependent_value[@source.class.primary_key_field]
                    }
                  end

                  if association[:joining_source]
                    joining_data = association[:joining_source].instance.send(
                      :"by_#{association[:joining_associated_column_name]}",
                      dependent_values
                    )

                    dependent_data = association[:source].instance.send(
                      :"by_#{association[:source].primary_key_field}",
                      association[:source].container.connection.adapter.restrict_to_attribute(
                        association[:joining_column_name], joining_data
                      ).map { |result|
                        result[association[:joining_column_name]]
                      }
                    )

                    case association[:dependent]
                    when :delete
                      joining_data.delete
                    when :nullify
                      joining_data.update(association[:joining_associated_column_name] => nil)
                    end
                  else
                    dependent_data = association[:source].instance.send(
                      :"by_#{association[:associated_column_name]}",
                      dependent_values
                    )
                  end

                  case association[:dependent]
                  when :delete
                    dependent_data.delete
                  when :nullify
                    unless association[:joining_source]
                      dependent_data.update(association[:associated_column_name] => nil)
                    end
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
                # Ensure that has_one associations only have one associated object.
                #
                @source.class.associations[:belongs_to].flat_map { |belongs_to_association|
                  belongs_to_association[:source].associations[:has_one].select { |has_one_association|
                    has_one_association[:associated_column_name] == belongs_to_association[:column_name]
                  }
                }.each do |association|
                  value = final_values.dig(
                    association[:associated_access_name], association[:column_name]
                  ) || final_values.dig(association[:associated_column_name])

                  if value
                    @source.class.instance.tap do |impacted_source|
                      impacted_source.__setobj__(
                        @source.class.container.connection.adapter.result_for_attribute_value(
                          association[:associated_column_name], value, impacted_source
                        )
                      )

                      impacted_source.update(association[:associated_column_name] => nil)
                    end
                  end
                end
              end

              command_result = @source.instance_exec(final_values, &@block)

              final_result = if @performs_update
                # For updates, we fetch the values prior to performing the update and
                # return a source containing locally updated values. This lets us see
                # the original values but prevents us from fetching twice.

                @source.class.container.source(@source.class.__object_name.name).tap do |updated_source|
                  updated_source.__setobj__(
                    @source.class.container.connection.adapter.result_for_attribute_value(
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

              if @performs_create || @performs_update
                # Update records associated with the data we just changed.
                #
                future_associated_changes.each do |association, association_value|
                  associated_dataset = case association_value
                  when Proxy
                    association_value
                  when Object, Array
                    updatable = Array.ensure(association_value).map { |value|
                      case value
                      when Object
                        value[association[:column_name]]
                      else
                        value
                      end
                    }

                    association[:source].instance.send(
                      :"by_#{association[:column_name]}", updatable
                    )
                  when NilClass
                    nil
                  end

                  if association[:joining_source]
                    associated_column_value = final_result.class.container.connection.adapter.restrict_to_attribute(
                      association[:column_name], final_result
                    )

                    # Disassociate old data.
                    #
                    association[:joining_source].instance.send(
                      :"by_#{association[:joining_associated_column_name]}",
                      associated_column_value
                    ).delete

                    if associated_dataset
                      associated_dataset_source = case associated_dataset
                      when Proxy
                        associated_dataset.source
                      else
                        associated_dataset
                      end

                      # Ensure that has_one through associations only have one associated object.
                      #
                      if association[:access_type] == :one
                        association[:joining_source].instance.send(
                          :"by_#{association[:joining_column_name]}",
                          association[:source].container.connection.adapter.restrict_to_attribute(
                            association[:column_name], associated_dataset_source
                          )
                        ).delete
                      end

                      # Associate the correct data.
                      #
                      associated_column_value.each do |result|
                        association[:source].container.connection.adapter.restrict_to_attribute(
                          association[:column_name], associated_dataset_source
                        ).each do |associated_result|
                          association[:joining_source].instance.command(:create).call(
                            association[:joining_column_name] => associated_result[association[:column_name]],
                            association[:joining_associated_column_name] => result[association[:associated_column_name]]
                          )
                        end
                      end
                    end
                  else
                    associated_column_value = final_result.one[association[:column_name]]

                    # Disassociate old data.
                    #
                    association[:source].instance.send(
                      :"by_#{association[:associated_column_name]}", associated_column_value
                    ).update(association[:associated_column_name] => nil)

                    # Associate the correct data.
                    #
                    if associated_dataset
                      associated_dataset.update(
                        association[:associated_column_name] => associated_column_value
                      )

                      # Update the column value in passed objects.
                      #
                      case association_value
                      when Proxy
                        association_value.source.reload
                      when Object, Array
                        Array.ensure(association_value).each do |object|
                          values = object.values.dup
                          values[association[:associated_column_name]] = associated_column_value
                          object.instance_variable_set(:@values, values.freeze)
                        end
                      end
                    end
                  end
                end
              end

              yield final_result if block_given?
              final_result
            end
          end
        end
      end
    end
  end
end
