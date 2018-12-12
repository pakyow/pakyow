# frozen_string_literal: true

require "pakyow/support/inflector"

require "pakyow/data/types"

module Pakyow
  module Data
    class Container
      attr_reader :connection, :sources

      def initialize(connection:, sources:, objects:)
        @connection, @sources = connection, sources

        @object_map = objects.each_with_object({}) { |object, map|
          map[object.__object_name.name] = object
        }
      end

      def source(source_name)
        plural_source_name = Support.inflector.pluralize(source_name).to_sym

        if found_source = sources.find { |source|
             source.plural_name == plural_source_name
           }

          found_source.new(
            @connection.dataset_for_source(found_source)
          )
        else
          # TODO: raise UnknownSource
        end
      end

      def object(object_name)
        @object_map.fetch(object_name, Object)
      end

      def finalize!(other_containers)
        sources_to_finalize.each do |source|
          set_container_for_source!(source)
          define_inverse_associations!(source, other_containers)
        end

        sources_to_finalize.each do |source|
          mixin_commands!(source)
          mixin_dataset_methods!(source)
          define_attributes_for_associations!(source, other_containers)
          define_queries_for_attributes!(source)
          wrap_defined_queries!(source)
          define_methods_for_associations!(source)
          define_methods_for_objects!(source)
          finalize_source_types!(source)
          source.finalized!
        end
      end

      private

      def adapter
        @connection.adapter
      end

      def sources_to_finalize
        @sources.reject(&:finalized?)
      end

      def set_container_for_source!(source)
        source.container = self
      end

      def mixin_commands!(source)
        source.include adapter.class.const_get("Commands")
      end

      def mixin_dataset_methods!(source)
        source.extend adapter.class.const_get("DatasetMethods")
      end

      def define_attributes_for_associations!(source, other_containers)
        source.associations.values.flatten.each do |association|
          associated_source = (@sources + other_containers.flat_map(&:sources)).find { |potentially_associated_source|
            potentially_associated_source.plural_name == association[:source_name]
          }

          if associated_source
            association[:source] = associated_source

            if association[:type] == :belongs_to
              association[:column_name] = :"#{association[:access_name]}_#{associated_source.primary_key_field}"
              association[:column_type] = associated_source.primary_key_type
              association[:associated_column_name] = associated_source.primary_key_field

              source.attribute(
                association[:column_name],
                association[:column_type],
                foreign_key: association[:source_name]
              )
            end
          end
        end
      end

      def define_inverse_associations!(source, other_containers)
        (source.associations[:has_many] + source.associations[:has_one]).each do |association|
          associated_source = (@sources + other_containers.flat_map(&:sources)).find { |potentially_associated_source|
            potentially_associated_source.plural_name == association[:source_name]
          }

          if associated_source
            unless associated_source.associations[:belongs_to].any? { |current_association| current_association[:access_name] == association[:associated_access_name] }
              associated_source.belongs_to(association[:associated_access_name], source: source.plural_name)
            end
          end
        end
      end

      def define_queries_for_attributes!(source)
        source.attributes.keys.each do |attribute|
          source.class_eval do
            method_name = :"by_#{attribute}"
            define_method method_name do |value|
              self.class.container.connection.adapter.result_for_attribute_value(attribute, value, self)
            end

            # Qualify the query.
            #
            subscribe :"by_#{attribute}", attribute => :__arg0__
          end
        end
      end

      def define_methods_for_associations!(source)
        source.associations.values.flatten.each do |association|
          source.class_eval do
            define_method :"with_#{association[:access_name]}" do
              including(association[:access_name])
            end
          end
        end
      end

      def define_methods_for_objects!(source)
        @object_map.keys.each do |object_name|
          source.class_eval do
            define_method :"as_#{object_name}" do
              as(object_name)
            end
          end
        end
      end

      # Override queries with methods that update the source with a new dataset.
      #
      def wrap_defined_queries!(source)
        local_queries = source.queries
        source.prepend(
          Module.new do
            local_queries.each do |query|
              define_method query do |*args, &block|
                tap do
                  result = super(*args, &block)
                  case result
                  when self.class
                    result
                  else
                    __setobj__(result)
                  end
                end
              end
            end
          end
        )
      end

      def finalize_source_types!(source)
        source.attributes.each do |attribute_name, attribute_info|
          type = Types.type_for(attribute_info[:type], connection.types)

          if attribute_name == source.primary_key_field
            type = type.meta(primary_key: true)
          end

          source.attributes[attribute_name] = type.meta(attribute_info[:options])
        end
      end
    end
  end
end
