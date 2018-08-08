# frozen_string_literal: true

require "pakyow/environment"

module Pakyow
  class Framework
    class << self
      # rubocop:disable Naming/MethodName
      def Framework(name)
        Class.new(self) do
          @framework_name = name
        end
      end
      # rubocop:enabled Naming/MethodName

      def inherited(framework_class)
        super

        return unless instance_variable_defined?(:@framework_name)
        Pakyow.register_framework(@framework_name, framework_class)
      end
    end

    context = self
    Pakyow.singleton_class.class_eval do
      define_method :Framework do |name|
        context.Framework(name)
      end
    end

    attr_reader :app

    def initialize(app)
      @app = app
    end

    def subclass(class_to_subclass)
      subclass_name = Support.inflector.demodulize(class_to_subclass.name).to_sym

      subclass = Class.new(class_to_subclass)

      unless app.const_defined?(subclass_name)
        app.const_set(subclass_name, subclass)
      end

      defined_subclass = app.const_get(subclass_name)
      defined_subclass.class_eval(&Proc.new) if block_given?
      defined_subclass
    end
  end
end
