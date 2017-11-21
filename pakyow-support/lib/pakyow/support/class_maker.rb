# frozen_string_literal: true

module Pakyow
  module Support
    module ClassMaker
      attr_reader :name, :state

      def make(name, state: nil, **args, &block)
        klass, name = class_const_for_name(Class.new(self), name)

        klass.class_eval do
          @name, @state = name, state

          args.each do |arg, value|
            instance_variable_set(:"@#{arg}", value)
          end

          class_eval(&block) if block_given?
        end

        klass
      end

      protected

      def class_const_for_name(klass, name)
        unless name.nil?
          target, name = ClassMaker.target_and_name(name)
          ClassMaker.define_object_on_target_with_name(klass, target, ClassMaker.camelize(name))
        end

        return klass, name
      end

      CLASS_SEPARATOR = "_".freeze
      MODULE_SEPARATOR = "__".freeze

      def self.target_and_name(name)
        parts = name.to_s.split(MODULE_SEPARATOR)
        class_name = parts.pop.to_sym

        target = Object
        parts.each do |namespace|
          target = ClassMaker.define_object_on_target_with_name(Module.new, target, ClassMaker.camelize(namespace))
        end

        return target, class_name
      end

      def self.define_object_on_target_with_name(object, target, name)
        unless target.const_defined?(name, false)
          target.const_set(name, object)
        end

        target.const_get(name)
      end

      def self.camelize(string)
        string.to_s.split(CLASS_SEPARATOR).map(&:capitalize).join
      end
    end
  end
end
