# frozen_string_literal: true

require "pakyow/support/inflector"

require "pakyow/data/types"

module Pakyow
  module Data
    # @api private
    class Container
      attr_reader :connection, :sources

      def initialize(connection:, sources:, objects:)
        @connection, @sources = connection, sources

        @object_map = objects.each_with_object({}) { |object, map|
          map[object.object_name.name] = object
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
        end
      end

      def object(object_name)
        @object_map.fetch(object_name, Object)
      end

      def finalize_associations!(other_containers)
        @sources.each do |source|
          discover_has_and_belongs_to!(source, other_containers)
        end

        @sources.each do |source|
          set_container_for_source!(source)
          define_reciprocal_associations!(source, other_containers)
        end
      end

      def finalize_sources!(other_containers)
        @sources.each do |source|
          mixin_commands!(source)
          mixin_dataset_methods!(source)
          define_attributes_for_associations!(source, other_containers)
          define_queries_for_attributes!(source)
          wrap_defined_queries!(source)
          define_methods_for_associations!(source)
          define_methods_for_objects!(source)
          finalize_source_types!(source)
        end
      end

      private

      def adapter
        @connection.adapter
      end

      def discover_has_and_belongs_to!(source, other_containers)
        source.associations.values.flatten.select { |association|
          # Only look for has_* associations that aren't already setup through another source.
          #
          association.type == :has
        }.each do |association|
          reciprocal_association = nil
          reciprocal_source = (@sources + other_containers.flat_map(&:sources)).reject { |potentially_reciprocal_source|
            potentially_reciprocal_source == source
          }.find { |potentially_reciprocal_source|
            reciprocal_association = potentially_reciprocal_source.associations.values.flatten.find { |potentially_reciprocal_association|
              potentially_reciprocal_association.specific_type == association.specific_type &&
                potentially_reciprocal_association.associated_source_name == source.plural_name &&
                Support.inflector.pluralize(potentially_reciprocal_association.name) == Support.inflector.pluralize(association.associated_name) &&
                Support.inflector.pluralize(potentially_reciprocal_association.associated_name) == Support.inflector.pluralize(association.name)
            }
          }

          if reciprocal_source
            joining_source_name = [source.plural_name, reciprocal_source.plural_name].sort.join("_")
            joining_source = (@sources + other_containers.flat_map(&:sources)).find { |potentially_joining_source|
              potentially_joining_source.plural_name == joining_source_name
            }

            unless joining_source
              joining_source = source.ancestors.find { |ancestor|
                ancestor != source && ancestor.ancestors.include?(Sources::Base)
              }.make(
                source.object_name.namespace,
                joining_source_name,
                adapter: source.adapter,
                connection: source.connection,
                primary_id: true,
                timestamps: true
              )

              @sources << joining_source
            end

            # Modify both sides of the association to be through the joining source.
            #
            source.setup_as_through(association, through: joining_source_name).internal!
            reciprocal_source.setup_as_through(reciprocal_association, through: joining_source_name).internal!
          end
        end
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
            potentially_associated_source.plural_name == association.associated_source_name
          }

          if associated_source
            association.associated_source = associated_source

            if association.type == :through
              association.joining_source = (@sources + other_containers.flat_map(&:sources)).find { |potentially_joining_source|
                potentially_joining_source.plural_name == association.joining_source_name
              }
            end

            if association.type == :belongs
              # Define an attribute for the foreign key.
              #
              source.attribute(
                association.foreign_key_field,
                association.foreign_key_type,
                foreign_key: association.associated_source.dataset_table
              )
            end
          end
        end
      end

      def define_reciprocal_associations!(source, other_containers)
        (source.associations[:has_many] + source.associations[:has_one]).each do |association|
          associated_source = (@sources + other_containers.flat_map(&:sources)).find { |potentially_associated_source|
            potentially_associated_source.plural_name == association.associated_source_name
          }

          if associated_source
            if association.type == :through
              joining_source = (@sources + other_containers.flat_map(&:sources)).find { |potential_joining_source|
                potential_joining_source.plural_name == association.joining_source_name
              }

              if joining_source
                unless joining_source.associations[:belongs_to].any? { |current_association| current_association.name == association.left_name }
                  joining_source.belongs_to(association.left_name, source: associated_source.plural_name)
                end

                unless joining_source.associations[:belongs_to].any? { |current_association| current_association.name == association.right_name }
                  joining_source.belongs_to(association.right_name, source: source.plural_name)
                end

                unless association.internal?
                  unless associated_source.associations[association.specific_type].any? { |current_association| current_association.type == :through && current_association.joining_source_name == association.joining_source_name }
                    associated_source.send(association.specific_type, association.associated_name, source: source.plural_name, as: association.left_name, through: association.joining_source_name, dependent: association.dependent)
                  end

                  unless source.associations[association.specific_type].any? { |current_association| current_association.type == :through && current_association.associated_source_name == association.joining_source_name }
                    source.send(association.specific_type, association.joining_source_name, source: joining_source.plural_name, as: Support.inflector.singularize(association.associated_name), dependent: association.dependent)
                  end
                end
              end
            else
              unless associated_source.associations[:belongs_to].any? { |current_association| current_association.name == Support.inflector.singularize(association.associated_name).to_sym }
                associated_source.belongs_to(association.associated_name, source: source.plural_name)
              end
            end
          end
        end
      end

      def define_queries_for_attributes!(source)
        source.attributes.keys.each do |attribute|
          method_name = :"by_#{attribute}"
          unless source.instance_methods.include?(method_name)
            source.class_eval do
              define_method method_name do |value|
                self.class.container.connection.adapter.result_for_attribute_value(attribute, value, self)
              end

              # Qualify the query.
              #
              subscribe :"by_#{attribute}", attribute => :__arg0__
            end
          end
        end
      end

      def define_methods_for_associations!(source)
        source.associations.values.flatten.each do |association|
          method_name = :"with_#{association.name}"
          unless source.instance_methods.include?(method_name)
            source.class_eval do
              define_method method_name do
                including(association.name)
              end
            end
          end
        end
      end

      def define_methods_for_objects!(source)
        @object_map.keys.each do |object_name|
          method_name = :"as_#{object_name}"
          unless source.instance_methods.include?(method_name)
            source.class_eval do
              define_method method_name do
                as(object_name)
              end
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
          if attribute_info.is_a?(Hash)
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
end
