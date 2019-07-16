# frozen_string_literal: true

require "pakyow/support/deep_dup"
require "pakyow/support/extension"

module Pakyow
  class Application
    class Connection
      module Behavior
        module Values
          extend Support::Extension
          using Support::DeepDup

          # @api private
          attr_reader :values

          apply_extension do
            after "initialize" do
              @values = {}
            end

            after "dup" do
              @values = @values.deep_dup
            end
          end

          def set?(key)
            @values.key?(key.to_sym)
          end

          def set(key, value)
            @values[key.to_sym] = value
          end

          def get(key)
            @values[key.to_sym]
          end
        end
      end
    end
  end
end
