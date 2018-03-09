# frozen_string_literal: true

require "pakyow/core/errors"
require "pakyow/core/verifier"

module Pakyow
  module Verification
    def self.included(base)
      base.extend(ClassMethods)
    end

    def verify(&block)
      object_to_verify = public_send(self.class.object_name_to_verify)

      verifier = Class.new(Verifier)
      verifier.instance_exec(&block)

      verifier_instance = verifier.new(object_to_verify, context: self)
      verifier_instance.verify? || raise(InvalidData.new(verifier_instance))
    end

    module ClassMethods
      attr_reader :object_name_to_verify

      def inherited(subclass)
        super

        subclass.instance_variable_set(:@object_name_to_verify, @object_name_to_verify)
      end

      def verifies(object)
        @object_name_to_verify = object
      end
    end
  end
end
