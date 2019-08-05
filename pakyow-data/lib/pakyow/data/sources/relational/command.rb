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

          def initialize(name, block:, source:, provides_dataset:, creates:, updates:, deletes:)
            @name, @block, @source, @provides_dataset, @creates, @updates, @deletes = name, block, source, provides_dataset, creates, updates, deletes
          end

          def call(values = {})
            future_associated_changes = []

            if values
              # Enforce required attributes.
              #
              @source.class.attributes.each do |attribute_name, attribute|
                if attribute.meta[:required]
                  if @creates && !values.include?(attribute_name)
                    raise NotNullViolation.new_with_message(attribute: attribute_name)
                  end

                  if values.include?(attribute_name) && values[attribute_name].nil?
                    raise NotNullViolation.new_with_message(attribute: attribute_name)
                  end
                end
              end

              # Fail if unexpected values were passed.
              #
              values.keys.each do |key|
                key = key.to_sym
                unless @source.class.attributes.include?(key) || @source.class.association_with_name?(key)
                  raise UnknownAttribute.new_with_message(attribute: key, source: @source.class.__object_name.name)
                end
              end

              # Coerce values into the appropriate type.
              #
              final_values = values.each_with_object({}) { |(key, value), values_hash|
                key = key.to_sym

                begin
                  if attribute = @source.class.attributes[key]
                    if value.is_a?(Proxy) || value.is_a?(Result) || value.is_a?(Object)
                      raise TypeMismatch.new_with_message(type: value.class, mapping: attribute.meta[:mapping])
                    end

                    values_hash[key] = value.nil? ? value : attribute[value]
                  else
                    values_hash[key] = value
                  end
                rescue TypeError, Dry::Types::CoercionError => error
                  raise TypeMismatch.build(error, type: value.class, mapping: attribute.meta[:mapping])
                end
              }

              # Update timestamp fields.
              #
              if timestamp_fields = @source.class.timestamp_fields
                if @creates
                  timestamp_fields.values.each do |timestamp_field|
                    final_values[timestamp_field] = Time.now
                  end
                # Don't update timestamps if we aren't also updating other values.
                #
                elsif values.any? && timestamp_field = timestamp_fields[@name]
                  final_values[timestamp_field] = Time.now
                end
              end

              if @creates
                # Set default values.
                #
                @source.class.attributes.each do |attribute_name, attribute|
                  if !final_values.include?(attribute_name) && attribute.meta.include?(:default)
                    default = attribute.meta[:default]
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
                final_values.key?(association.name)
              }.each do |association|
                association_value = raw_result(final_values[association.name])

                case association_value
                when Proxy
                  if association_value.source.class.__object_name.name == association.associated_source.__object_name.name
                    if association.result_type == :one && (association_value.count > 1 || (@updates && @source.count > 1))
                      raise ConstraintViolation.new_with_message(
                        :associate_multiple,
                        association: association.name
                      )
                    end
                  else
                    raise TypeMismatch.new_with_message(
                      :associate_wrong_source,
                      source: association_value.source.class.__object_name.name,
                      association: association.name
                    )
                  end
                when Object
                  if association.result_type == :one
                    if association_value.originating_source
                      if association_value.originating_source.__object_name.name == association.associated_source.__object_name.name
                        if association.associated_source.instance.send(:"by_#{association.associated_source.primary_key_field}", association_value[association.associated_source.primary_key_field]).count == 0
                          raise ConstraintViolation.new_with_message(
                            :associate_missing,
                            source: association.name,
                            field: association.associated_source.primary_key_field,
                            value: association_value[association.associated_source.primary_key_field]
                          )
                        end
                      else
                        raise TypeMismatch.new_with_message(
                          :associate_wrong_object,
                          source: association_value.originating_source.__object_name.name,
                          association: association.name
                        )
                      end
                    else
                      raise TypeMismatch.new_with_message(
                        :associate_unknown_object,
                        association: association.name
                      )
                    end
                  else
                    raise TypeMismatch.new_with_message(
                      :associate_wrong_type,
                      type: association_value.class,
                      association: association.name
                    )
                  end
                when Array
                  if association.result_type == :many
                    if association_value.any? { |value| !value.is_a?(Object) }
                      raise TypeMismatch.new_with_message(
                        :associate_many_not_object,
                        association: association.name
                      )
                    else
                      if association_value.any? { |value| value.originating_source.nil? }
                        raise TypeMismatch.new_with_message(
                          :associate_unknown_object,
                          association: association.name
                        )
                      else
                        if association_value.find { |value| value.originating_source != association.associated_source }
                          raise TypeMismatch.new_with_message(
                            :associate_many_wrong_source,
                            association: association.name,
                            source: association.associated_source_name
                          )
                        else
                          associated_column_value = association_value.map { |object| object[association.associated_source.primary_key_field] }
                          associated_object_query = association.associated_source.instance.send(
                            :"by_#{association.associated_source.primary_key_field}", associated_column_value
                          )

                          if associated_object_query.count != association_value.count
                            raise ConstraintViolation.new_with_message(
                              :associate_many_missing,
                              association: association.name
                            )
                          end
                        end
                      end
                    end
                  else
                    raise ConstraintViolation.new_with_message(
                      :associate_multiple,
                      association: association.name
                    )
                  end
                when NilClass
                else
                  raise TypeMismatch.new_with_message(
                    :associate_wrong_type,
                    type: association_value.class,
                    association: association.name
                  )
                end
              end

              # Enforce constraints for association values passed by foreign key.
              #
              @source.class.associations.values.flatten.select { |association|
                association.type == :belongs && final_values.key?(association.foreign_key_field) && !final_values[association.foreign_key_field].nil?
              }.each do |association|
                associated_column_value = final_values[association.foreign_key_field]
                associated_object_query = association.associated_source.instance.send(
                  :"by_#{association.associated_query_field}", associated_column_value
                )

                if associated_object_query.count == 0
                  raise ConstraintViolation.new_with_message(
                    :associate_missing,
                    source: association.name,
                    field: association.associated_query_field,
                    value: associated_column_value
                  )
                end
              end

              # Set values for associations passed by access name.
              #
              @source.class.associations.values.flatten.select { |association|
                final_values.key?(association.name)
              }.each do |association|
                case association.specific_type
                when :belongs_to
                  association_value = raw_result(final_values.delete(association.name))
                  final_values[association.query_field] = case association_value
                  when Proxy
                    if association_value.one.nil?
                      nil
                    else
                      association_value.one[association.associated_source.primary_key_field]
                    end
                  when Object
                    association_value[association.associated_source.primary_key_field]
                  when NilClass
                    nil
                  end
                when :has_one, :has_many
                  future_associated_changes << [association, final_values.delete(association.name)]
                end
              end
            end

            original_dataset = if @updates
              # Hold on to the original values so we can update them locally.
              @source.dup.to_a
            else
              nil
            end

            unless @provides_dataset || @updates
              # Cache the result prior to running the command.
              @source.to_a
            end

            @source.transaction do
              if @deletes
                @source.class.associations.values.flatten.select(&:dependents?).each do |association|
                  dependent_values = @source.class.container.connection.adapter.restrict_to_attribute(
                    @source.class.primary_key_field, @source
                  )

                  # If objects are located in two different connections, fetch the raw values.
                  #
                  unless @source.class.container.connection == association.associated_source.container.connection
                    dependent_values = dependent_values.map { |dependent_value|
                      dependent_value[@source.class.primary_key_field]
                    }
                  end

                  if association.type == :through
                    joining_data = association.joining_source.instance.send(
                      :"by_#{association.right_foreign_key_field}",
                      dependent_values
                    )

                    dependent_data = association.associated_source.instance.send(
                      :"by_#{association.associated_source.primary_key_field}",
                      association.associated_source.container.connection.adapter.restrict_to_attribute(
                        association.left_foreign_key_field, joining_data
                      ).map { |result|
                        result[association.left_foreign_key_field]
                      }
                    )

                    case association.dependent
                    when :delete
                      joining_data.delete
                    when :nullify
                      joining_data.update(association.right_foreign_key_field => nil)
                    end
                  else
                    dependent_data = association.associated_source.instance.send(
                      :"by_#{association.associated_query_field}",
                      dependent_values
                    )
                  end

                  case association.dependent
                  when :delete
                    dependent_data.delete
                  when :nullify
                    unless association.type == :through
                      dependent_data.update(association.associated_query_field => nil)
                    end
                  when :raise
                    dependent_count = dependent_data.count
                    if dependent_count > 0
                      dependent_name = if dependent_count > 1
                        Support.inflector.pluralize(association.associated_source_name)
                      else
                        Support.inflector.singularize(association.associated_source_name)
                      end

                      raise ConstraintViolation.new_with_message(
                        :dependent_delete,
                        source: @source.class.__object_name.name,
                        count: dependent_count,
                        dependent: dependent_name
                      )
                    end
                  end
                end
              end

              if @creates || @updates
                # Ensure that has_one associations only have one associated object.
                #
                @source.class.associations[:belongs_to].flat_map { |belongs_to_association|
                  belongs_to_association.associated_source.associations[:has_one].select { |has_one_association|
                    has_one_association.associated_source == @source.class &&
                      has_one_association.associated_query_field == belongs_to_association.query_field
                  }
                }.each do |association|
                  value = final_values.dig(
                    association.associated_name, association.query_field
                  ) || final_values.dig(association.associated_query_field)

                  if value
                    @source.class.instance.tap do |impacted_source|
                      impacted_source.__setobj__(
                        @source.class.container.connection.adapter.result_for_attribute_value(
                          association.associated_query_field, value, impacted_source
                        )
                      )

                      impacted_source.update(association.associated_query_field => nil)
                    end
                  end
                end
              end

              command_result = @source.instance_exec(final_values, &@block)

              final_result = if @updates
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
                    new_object = original_object.class.new(original_object.values.merge(final_values))
                    new_object.originating_source = original_object.originating_source
                    new_object
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

              if @creates || @updates
                # Update records associated with the data we just changed.
                #
                future_associated_changes.each do |association, association_value|
                  association_value = raw_result(association_value)
                  associated_dataset = case association_value
                  when Proxy
                    association_value
                  when Object, Array
                    updatable = Array.ensure(association_value).map { |value|
                      case value
                      when Object
                        value[association.associated_source.primary_key_field]
                      else
                        value
                      end
                    }

                    association.associated_source.instance.send(
                      :"by_#{association.associated_source.primary_key_field}", updatable
                    )
                  when NilClass
                    nil
                  end

                  if association.type == :through
                    associated_column_value = final_result.class.container.connection.adapter.restrict_to_attribute(
                      association.query_field, final_result
                    )

                    # If objects are located in two different connections, fetch the raw values.
                    #
                    if association.joining_source.container.connection == final_result.class.container.connection
                      disassociate_column_value = associated_column_value
                    else
                      disassociate_column_value = associated_column_value.map { |value|
                        value[association.query_field]
                      }
                    end

                    # Disassociate old data.
                    #
                    association.joining_source.instance.send(
                      :"by_#{association.right_foreign_key_field}",
                      disassociate_column_value
                    ).delete

                    if associated_dataset
                      associated_dataset_source = case raw_result(associated_dataset)
                      when Proxy
                        associated_dataset.source
                      else
                        associated_dataset
                      end

                      # Ensure that has_one through associations only have one associated object.
                      #
                      if association.result_type == :one
                        joined_column_value = association.associated_source.container.connection.adapter.restrict_to_attribute(
                          association.associated_source.primary_key_field, associated_dataset_source
                        )

                        # If objects are located in two different connections, fetch the raw values.
                        #
                        unless association.joining_source.container.connection == association.associated_source.container.connection
                          joined_column_value = joined_column_value.map { |value|
                            value[association.associated_source.primary_key_field]
                          }
                        end

                        association.joining_source.instance.send(
                          :"by_#{association.left_foreign_key_field}",
                          joined_column_value
                        ).delete
                      end

                      # Associate the correct data.
                      #
                      associated_column_value.each do |result|
                        association.associated_source.container.connection.adapter.restrict_to_attribute(
                          association.associated_source.primary_key_field, associated_dataset_source
                        ).each do |associated_result|
                          association.joining_source.instance.command(:create).call(
                            association.left_foreign_key_field => associated_result[association.associated_source.primary_key_field],
                            association.right_foreign_key_field => result[association.source.primary_key_field]
                          )
                        end
                      end
                    end
                  else
                    if final_result.one
                      associated_column_value = final_result.one[association.query_field]

                      # Disassociate old data.
                      #
                      association.associated_source.instance.send(
                        :"by_#{association.associated_query_field}", associated_column_value
                      ).update(association.associated_query_field => nil)

                      # Associate the correct data.
                      #
                      if associated_dataset
                        associated_dataset.update(
                          association.associated_query_field => associated_column_value
                        )

                        # Update the column value in passed objects.
                        #
                        case association_value
                        when Proxy
                          association_value.source.reload
                        when Object, Array
                          Array.ensure(association_value).each do |object|
                            values = object.values.dup
                            values[association.associated_query_field] = associated_column_value
                            object.instance_variable_set(:@values, values.freeze)
                          end
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

          private

          def raw_result(value)
            if value.is_a?(Result)
              value.__getobj__
            elsif value.is_a?(Array)
              value.map { |each_value|
                raw_result(each_value)
              }
            else
              value
            end
          end
        end
      end
    end
  end
end
