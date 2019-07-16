# frozen_string_literal: true

require "pakyow/support/class_state"
require "pakyow/support/deep_dup"
require "pakyow/support/extension"

require "pakyow/errors"
require "pakyow/verifier"

module Pakyow
  module Behavior
    module Verification
      extend Support::Extension
      using Support::DeepDup

      def verify(values = nil, &block)
        unless values
          if self.class.__object_name_to_verify.nil?
            raise "Expected values to be passed"
          else
            values = public_send(self.class.__object_name_to_verify)
          end
        end

        original_values = values.deep_dup
        result = Pakyow::Verifier.new(&block).call(values, context: self)

        unless result.verified?
          error = InvalidData.new_with_message(:verification)
          error.context = { object: original_values, result: result }
          raise error
        end
      end

      apply_extension do
        extend Support::ClassState
        class_state :__object_name_to_verify, inheritable: true
      end

      class_methods do
        def verifies(object)
          @__object_name_to_verify = object
        end
      end
    end
  end
end
