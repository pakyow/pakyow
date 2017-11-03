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
        return klass if name.nil? || !defined?(CLASS_MAKER_BASE)

        class_name = "#{name.to_s.split('_').map(&:capitalize).join}#{CLASS_MAKER_BASE}"

        if Object.const_defined?(class_name)
          klass
        else
          Object.const_set(class_name, klass)
        end
      end
    end
  end
end
