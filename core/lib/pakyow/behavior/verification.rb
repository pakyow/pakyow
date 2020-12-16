# frozen_string_literal: true

require "forwardable"

require "pakyow/support/class_state"
require "pakyow/support/extension"

require_relative "../verifier"

module Pakyow
  module Behavior
    module Verification
      extend Support::Extension

      def verify(name_or_values = name_or_values_omitted = true, values_or_name = values_or_name_omitted = true, &block)
        name, values = :default, nil
        if name_or_values_omitted
          # intentionally empty
        elsif name_or_values.is_a?(Symbol)
          name = name_or_values
          unless values_or_name_omitted
            values = values_or_name
          end
        else
          values = name_or_values
        end

        if values.nil?
          if self.class.__verifiable_object_name.nil?
            raise "Expected values to be passed"
          else
            values = public_send(self.class.__verifiable_object_name)
          end
        end

        verifier = if block
          Pakyow::Verifier.new(&block)
        else
          self.class.__verifiers[name]
        end

        verifier&.call!(values, context: self)
      end

      apply_extension do
        extend Support::ClassState
        class_state :__verifiable_object_name, inheritable: true
        class_state :__verifiers, default: {}, inheritable: true
      end

      class_methods do
        def verifies(name)
          @__verifiable_object_name = name
        end

        def verify(name = :default, &block)
          name = name.to_sym
          if (verifier = __verifiers[name])
            if block
              verifier.instance_eval(&block)
            end
          else
            verifier = if block
              Pakyow::Verifier.new(&block)
            else
              Pakyow::Verifier.new
            end

            __verifiers[name] = verifier
          end

          verifier
        end

        extend Forwardable
        def_delegators :verify, :required, :optional
      end
    end
  end
end
