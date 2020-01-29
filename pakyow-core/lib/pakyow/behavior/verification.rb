# frozen_string_literal: true

require "pakyow/support/class_state"
require "pakyow/support/extension"

require "pakyow/verifier"

module Pakyow
  module Behavior
    module Verification
      extend Support::Extension

      def verify(values = nil, &block)
        unless values
          if self.class.object_name_to_verify.nil?
            raise "Expected values to be passed"
          else
            values = public_send(self.class.object_name_to_verify)
          end
        end

        Pakyow::Verifier.new(&block).call!(values, context: self)
      end

      apply_extension do
        extend Support::ClassState
        class_state :object_name_to_verify, inheritable: true
      end

      class_methods do
        def verifies(object)
          @object_name_to_verify = object
        end
      end
    end
  end
end
