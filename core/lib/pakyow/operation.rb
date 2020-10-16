# frozen_string_literal: true

require "pakyow/support/class_state"
require "pakyow/support/deprecatable"
require "pakyow/support/handleable"
require "pakyow/support/makeable"
require "pakyow/support/pipeline"
require "pakyow/support/thread_localizer"

require_relative "behavior/verification"

module Pakyow
  class Operation
    extend Support::Deprecatable

    include Support::Handleable
    include Support::Makeable
    include Support::Pipeline
    include Support::ThreadLocalizer

    include Behavior::Verification

    attr_reader :__values

    def initialize(**values)
      @__values = values
      result = verify(values)
      values.each_pair do |key, value|
        if result&.default?(key)
          instance_variable_set(:"@#{key}", value)
        else
          send(:"#{key}=", value)
        end
      end

      # Ensure that every potential value has an instance variable.
      #
      self.class.__verifiers.each_value do |verifier|
        verifier.allowable_keys.each do |key|
          unless values.include?(key)
            instance_variable_set(:"@#{key}", nil)
          end
        end
      end

      @__latest_result = nil
    end

    def perform(*args, **kwargs)
      handling do
        result = call(*args, **kwargs)
        thread_localize(:result, result)
        @__latest_result ||= result
      end

      self
    end

    def result
      thread_localized(:result, @__latest_result)
    end

    def method_missing(name, *args, &block)
      value_key = if name[-1] == "="
        setter = true
        name[0..-2].to_sym
      else
        name.to_sym
      end

      if @__values.key?(value_key)
        if setter
          instance_variable_set(:"@#{value_key}", *args)
        else
          instance_variable_get(:"@#{value_key}")
        end
      else
        super
      end
    end

    def respond_to_missing?(name, include_private = false)
      value_key = if name[-1] == "="
        name[0..-2].to_sym
      else
        name.to_sym
      end

      @__values.key?(value_key) || super
    end

    def values
      @__values
    end
    deprecate :values, solution: "prefer value methods"

    private def deprecated_method_reference(target)
      target = if target.is_a?(Symbol) && target.to_s[-1] == "="
        target[0..-2].to_sym
      else
        target
      end

      if self.class.__verifiers[:default]&.allowable_keys&.include?(target)
        [self, "verified value `#{target}'"]
      else
        super
      end
    end

    class << self
      # @api private
      def deprecate(target = self, solution: "do not use")
        if __verifiers[:default]&.allowable_keys&.include?(target)
          super(:"#{target}=", solution: solution)
        end

        super(target, solution: solution)
      end

      # @api private
      def verify(name = :default, &block)
        verifier = super
        define_attributes_for_verifier(verifier)
        verifier
      end

      # @api private
      def required(*)
        return_value = super
        define_attributes_for_verifier(__verifiers[:default])
        return_value
      end

      # @api private
      def optional(*)
        return_value = super
        define_attributes_for_verifier(__verifiers[:default])
        return_value
      end

      private def define_attributes_for_verifier(verifier)
        verifier.allowable_keys.each do |key|
          unless method_defined?(key) || private_method_defined?(key)
            class_eval <<~CODE, __FILE__, __LINE__ + 1
              attr_reader :#{key}
            CODE
          end

          setter = :"#{key}="
          unless method_defined?(setter) || private_method_defined?(setter)
            class_eval <<~CODE, __FILE__, __LINE__ + 1
              private

              attr_writer :#{key}
            CODE
          end
        end
      end
    end
  end
end
