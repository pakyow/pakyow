# frozen_string_literal: true

require "pakyow/support/inflector"

module Pakyow
  module Support
    # @api private
    module ObjectMaker
      def self.define_const_for_object_with_name(object_to_define, object_name)
        return if object_name.nil?

        target = object_name.namespace.parts.inject(Object) { |target_for_part, object_name_part|
          ObjectMaker.define_object_on_target_with_constant_name(Module.new, target_for_part, object_name_part)
        }

        ObjectMaker.define_object_on_target_with_constant_name(object_to_define, target, object_name.name)
      end

      def self.define_object_on_target_with_constant_name(object, target, constant_name)
        constant_name = Support.inflector.camelize(constant_name)

        unless target.const_defined?(constant_name, false)
          target.const_set(constant_name, object)
        end

        target.const_get(constant_name)
      end
    end
  end
end
