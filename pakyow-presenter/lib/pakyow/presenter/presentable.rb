# frozen_string_literal: true

module Pakyow
  module Presenter
    module Presentable
      def method_missing(method_name, *args, &block)
        if @presentables.keys.any? { |key| key.to_s.start_with?(method_name.to_s) }
          @presentables[[method_name].concat(args).join(":").to_sym]
        else
          super
        end
      end

      def respond_to_missing?(method_name, include_private = false)
        @presentables.keys.any? { |key| key.to_s.start_with?(method_name.to_s) } || super
      end
    end
  end
end
