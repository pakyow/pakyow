# frozen_string_literal: true

module Pakyow
  module Data
    module Adapters
      class Sql
        module SourceExtension
          extend Support::Extension

          private def build(string, *args)
            Sequel.lit(string, *args)
          end

          apply_extension do
            class_state :dataset_table, default: self.object_name.name

            class << self
              def table(table_name)
                @dataset_table = table_name
              end

              def default_primary_key_type
                :bignum
              end
            end
          end
        end
      end
    end
  end
end
