module Pakyow
  module Support
    module ClassMaker
      attr_reader :name, :state

      def make(name, state: nil, **args, &block)
        klass = class_const_for_name(Class.new(self), name)

        klass.class_eval do
          @name = name
          @state = state

          class_eval(&block) if block_given?
        end

        klass
      end

      def class_const_for_name(klass, name)
        unless name.nil?
          target, defined_name = ClassMaker.target_and_name(name)
          ClassMaker.define_object_on_target_with_name(klass, target, defined_name)
        end

        klass
      end

      MODULE_SEPARATOR = "__".freeze
      CLASS_SEPARATOR = "_".freeze

      def self.target_and_name(name)
        parts = name.to_s.split(MODULE_SEPARATOR)
        class_name = ClassMaker.camelize(parts.pop)

        target = Object
        parts.each do |namespace|
          target = ClassMaker.define_object_on_target_with_name(Module.new, target, ClassMaker.camelize(namespace))
        end

        return target, class_name
      end

      def self.define_object_on_target_with_name(object, target, name)
        unless target.const_defined?(name)
          target.const_set(name, object)
        end

        target.const_get(name)
      end

      def self.camelize(string)
        string.split(CLASS_SEPARATOR).map(&:capitalize).join
      end
    end
  end
end
