# frozen_string_literal: true

require "pakyow/data/adapters/sql/differ"

module Pakyow
  module Data
    module Adapters
      class Sql
        class Migrator
          def initialize(connection)
            @connection = connection
          end

          def create?(source)
            !differ(source).exists?
          end

          def change?(source, attributes = source.attributes)
            create?(source) || differ(source, attributes).changes?
          end

          def create!(source, attributes)
            local_context = self
            differ = differ(source, attributes)
            create_table differ.table_name do
              differ.attributes.each do |attribute_name, attribute|
                local_context.send(:add_column_for_attribute, attribute_name, attribute, self)
              end
            end
          end

          def reassociate!(source, foreign_keys)
            foreign_keys.each do |foreign_key_name, foreign_key|
              differ = differ(source, { foreign_key_name => foreign_key })

              if create?(source) || differ.changes?
                local_context = self

                associate_table differ.table_name, with: foreign_key.meta[:foreign_key] do
                  attributes_to_add = if local_context.send(:create?, source)
                    differ.attributes
                  else
                    differ.attributes_to_add
                  end

                  attributes_to_add.each do |attribute_name, attribute|
                    local_context.send(:add_column_for_attribute, attribute_name, attribute, self, method_prefix: "add_")
                  end
                end
              end
            end
          end

          def change!(source, attributes)
            differ = differ(source, attributes)

            if differ.changes?
              local_context = self

              alter_table differ.table_name do
                differ.attributes_to_add.each do |attribute_name, attribute|
                  local_context.send(:add_column_for_attribute, attribute_name, attribute, self, method_prefix: "add_")
                end

                differ.column_types_to_change.each do |column_name, column_type|
                  local_context.send(:change_column_type_for_attribute, column_name, differ.attributes[column_name], self)
                end

                # TODO: revisit when we're ready to tackle foreign key removal
                #
                # differ.columns_to_remove.keys.each do |column_name|
                #   local_context.send(:remove_column_by_name, column_name, self)
                # end
              end
            end
          end

          private

          def differ(source, attributes = source.attributes)
            Differ.new(connection: @connection, source: source, attributes: attributes)
          end

          def add_column_for_attribute(attribute_name, attribute, context, method_prefix: "")
            if attribute.meta[:primary_key]
              context.send(:"#{method_prefix}primary_key", attribute_name, type: type_for_attribute(attribute))
            elsif attribute.meta[:foreign_key]
              context.send(:"#{method_prefix}foreign_key", attribute_name, attribute.meta[:foreign_key], type: type_for_attribute(attribute))
            else
              context.send(:"#{method_prefix}column", attribute_name, type_for_attribute(attribute), **column_opts_for_attribute(attribute))
            end
          end

          def change_column_type_for_attribute(attribute_name, attribute, context)
            context.set_column_type(attribute_name, type_for_attribute(attribute), **column_opts_for_attribute(attribute))
          end

          def remove_column_by_name(column_name, context)
            context.drop_column(column_name)
          end

          ALLOWED_COLUMN_OPTS = %i(size text)
          def column_opts_for_attribute(attribute)
            {}.tap do |opts|
              ALLOWED_COLUMN_OPTS.each do |opt|
                if attribute.meta.include?(opt)
                  opts[opt] = attribute.meta[opt]
                end
              end
            end
          end

          def column_opts_string_for_attribute(attribute)
            opts = column_opts_for_attribute(attribute)

            if opts.any?
              opts.each_with_object(String.new) { |(key, value), opts_string|
                opts_string << ", #{key}: #{value.inspect}"
              }
            else
              ""
            end
          end
        end
      end
    end
  end
end
