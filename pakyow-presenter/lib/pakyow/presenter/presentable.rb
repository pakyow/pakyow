# frozen_string_literal: true

module Pakyow
  module Presenter
    module Presentable
      def presentables
        initialize_presentables unless defined?(@presentables)
        @presentables
      end

      def presentable(name, default_value = default_omitted = true)
        raise ArgumentError, "name must a symbol" unless name.is_a?(Symbol)

        value = if block_given?
          yield
        elsif default_omitted
          __send__(name)
        end

        unless default_omitted
          value ||= default_value
        end

        presentables[name] = value
      end

      def initialize_presentables
        @presentables = {}
        @__state.set(:presentables, @presentables)
      end
    end
  end
end
