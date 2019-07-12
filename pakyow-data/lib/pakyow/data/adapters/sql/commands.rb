# frozen_string_literal: true

module Pakyow
  module Data
    module Adapters
      class Sql
        module Commands
          extend Support::Extension

          apply_extension do
            command :create, creates: true do |values|
              begin
                inserted_return_value = insert(values)
                if self.class.primary_key_field
                  if Migrator::AUTO_INCREMENTING_TYPES.include?(self.class.primary_key_type)
                    where(self.class.primary_key_field => inserted_return_value)
                  else
                    where(self.class.primary_key_field => values[self.class.primary_key_field])
                  end
                else
                  where(values)
                end
              rescue Sequel::UniqueConstraintViolation => error
                raise UniqueViolation.build(error)
              rescue Sequel::ForeignKeyConstraintViolation => error
                raise ConstraintViolation.build(error)
              end
            end

            command :update, updates: true do |values|
              __getobj__.select(self.class.primary_key_field).map { |result|
                result[self.class.primary_key_field]
              }.tap do
                begin
                  unless values.empty?
                    update(values)
                  end
                rescue Sequel::UniqueConstraintViolation => error
                  raise UniqueViolation.build(error)
                rescue Sequel::ForeignKeyConstraintViolation => error
                  raise ConstraintViolation.build(error)
                end
              end
            end

            command :delete, provides_dataset: false, deletes: true do
              begin
                delete
              rescue Sequel::ForeignKeyConstraintViolation => error
                raise ConstraintViolation.build(error)
              end
            end
          end
        end
      end
    end
  end
end
