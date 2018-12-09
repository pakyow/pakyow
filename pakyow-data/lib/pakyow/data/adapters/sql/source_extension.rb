# frozen_string_literal: true

module Pakyow
  module Data
    module Adapters
      class Sql
        module SourceExtension
          extend Support::Extension

          apply_extension do
            def sql
              __getobj__.sql
            end

            class_state :dataset_table, default: self.__object_name.name

            class << self
              def table(table_name)
                @dataset_table = table_name
              end

              def primary_key_type
                :bignum
              end
            end
          end
        end
      end
    end
  end
end
