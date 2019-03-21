# frozen_string_literal: true

module Pakyow
  module Presenter
    module Presentable
      def method_missing(method_name, *args, &block)
        if presentable?(method_name)
          @presentables[args.unshift(method_name).join(":").to_sym]
        else
          super
        end
      end

      def respond_to_missing?(method_name, include_private = false)
        presentable?(method_name) || super
      end

      private

      def presentable?(presentable_key)
        presentable_key = presentable_key.to_s
        instance_variable_defined?(:@presentables) && @presentables.any? { |key, _|
          key.to_s.start_with?(presentable_key)
        }
      end
    end
  end
end
