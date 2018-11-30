# frozen_string_literal: true

module Pakyow
  module Data
    module Sources
      class Abstract < SimpleDelegator
        attr_reader :original_results

        def qualifications
          {}
        end

        def command?(_maybe_command_name)
          false
        end

        def query?(_maybe_query_name)
          false
        end

        def modifier?(_maybe_modifier_name)
          false
        end

        def result?(_maybe_result_name)
          false
        end

        # @api private
        def source_from_self(dataset = __getobj__)
          self.class.source_from_source(self, dataset)
        end

        class << self
          # @api private
          def source_from_source(source, dataset)
            source.dup.tap do |duped_source|
              duped_source.__setobj__(dataset)
            end
          end

          def primary_key_field
            :id
          end
        end
      end
    end
  end
end
