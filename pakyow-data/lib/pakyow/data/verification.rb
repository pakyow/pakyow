# frozen_string_literal: true

require "pakyow/data/verifier"

module Pakyow
  class InvalidData < Error
    # TODO: what should this expose? we want both schema processing and validation errors
    # attr_reader :validator

    # def initialize(validator = nil)
    #   @validator = validator
    #   super
    # end
  end

  module Data
    module Verification
      def self.included(base)
        base.extend(ClassMethods)
      end

      def verify(&block)
        object_to_verify = public_send(self.class.object_name_to_verify)

        verifier = Class.new(Verifier)
        verifier.instance_exec(&block)

        verifier_instance = verifier.new(object_to_verify)
        verifier_instance.verify? || raise(InvalidData.new)
      end

      module ClassMethods
        attr_reader :object_name_to_verify

        def verifies(object)
          @object_name_to_verify = object
        end
      end
    end
  end
end
