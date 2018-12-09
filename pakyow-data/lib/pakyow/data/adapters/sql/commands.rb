# frozen_string_literal: true

module Pakyow
  module Data
    module Adapters
      class Sql
        module Commands
          extend Support::Extension

          apply_extension do
            command :create, performs_create: true do |values|
              begin
                if inserted_primary_key = insert(values)
                  where(self.class.primary_key_field => inserted_primary_key)
                else
                  where(values)
                end
              rescue Sequel::UniqueConstraintViolation => error
                raise UniqueViolation.build(error)
              rescue Sequel::ForeignKeyConstraintViolation => error
                raise ConstraintViolation.build(error)
              end
            end

            command :update, performs_update: true do |values|
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

            command :delete, provides_dataset: false, performs_delete: true do
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
