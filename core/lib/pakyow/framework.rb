# frozen_string_literal: true

require_relative "environment"

module Pakyow
  # Base framework class.
  #
  class Framework
    class << self
      def Framework(name)
        Class.new(self) do
          @framework_name = name
        end
      end

      def inherited(framework_class)
        super

        return unless defined?(@framework_name)
        Pakyow.register_framework(@framework_name, framework_class)
      end
    end

    context = self
    Pakyow.singleton_class.class_eval do
      define_method :Framework do |name|
        context.Framework(name)
      end
    end

    attr_reader :object

    def initialize(object)
      @object = object
    end
  end
end
