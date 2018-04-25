# frozen_string_literal: true

module Pakyow
  module Data
    class Container
      attr_reader :connection, :sources

      def initialize(connection:, sources:, objects:)
        @connection, @sources = connection, sources

        @object_map = objects.each_with_object({}) { |object, map|
          map[object.__class_name.name] = object
        }

        # TODO: finalize the sources, which wires any interdependencies (e.g. inverse associations)

        # TODO: move this to a method
        sources.each do |source|
          source.attributes.each do |attribute_name, attribute_info|
            type = Types.type_for(attribute_info[:type], connection.types)

            # TODO: set metadata values for default, null

            # final_type = original_type

            # if attribute_info[:nullable] && source.primary_key_field != attribute_name
            #   final_type = final_type.optional
            # end

            # if attribute_info.key?(:default)
            #   final_type = final_type.default { attribute_info[:default] }
            # end

            source.attributes[attribute_name] = type
          end
        end
      end

      def source_instance(source_name)
        plural_source_name = Support.inflector.pluralize(source_name).to_sym

        if source = sources.find { |source|
             source.plural_name == plural_source_name
           }

          source.new(
            @connection.dataset_for_source(source),
            object_map: @object_map
          )
        else
          # TODO: raise UnknownSource
        end
      end
    end
  end
end
