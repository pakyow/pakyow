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
      unless verifier_instance.verify?
        InvalidData.new("Verification failed for #{object_to_verify}").tap do |error|
          error.context = {
            object: object_to_verify,
            verifier: verifier_instance
          }

          raise(error)
        end
      end
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
