# frozen_string_literal: true

module Pakyow
  module UI
    module Helpers
      UI_REQUEST_HEADER = "HTTP_PW_UI"

      def ui?
        @connection.env.key?(UI_REQUEST_HEADER)
      end

      def ui
        @connection.env[UI_REQUEST_HEADER]
      end

      def ui_transform?
        @connection.env.key?("pakyow.ui_transform")
      end
    end
  end
end
