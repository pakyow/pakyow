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

        class << self
          def primary_key_field
            :id
          end
        end
      end
    end
  end
end
