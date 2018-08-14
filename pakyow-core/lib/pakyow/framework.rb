# frozen_string_literal: true

require "pakyow/environment"

module Pakyow
  # Base framework class.
  #
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
  end
end
