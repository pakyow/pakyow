# frozen_string_literal: true

module Pakyow
  module UI
    module Helpers
      def ui?
        @connection.request_header?("pw-ui")
      end

      def ui
        @connection.request_header("pw-ui")
      end

      def ui_transform?
        @connection.set?(:__ui_transform)
      end
    end
  end
end
