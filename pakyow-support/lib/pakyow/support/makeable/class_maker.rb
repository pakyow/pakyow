# frozen_string_literal: true

require "pakyow/support/inflector"

module Pakyow
  module Support
    # @api private
    module ClassMaker
      def self.define_const_for_class_with_name(class_to_define, class_name)
        return if class_name.nil?

        target = class_name.namespace.parts.inject(Object) { |target_for_part, class_name_part|
          ClassMaker.define_object_on_target_with_constant_name(Module.new, target_for_part, class_name_part)
        }

        ClassMaker.define_object_on_target_with_constant_name(class_to_define, target, class_name.name)
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
