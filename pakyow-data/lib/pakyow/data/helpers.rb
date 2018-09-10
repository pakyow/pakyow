# frozen_string_literal: true

module Pakyow
  module Data
    module Helpers
      def data
        @connection.app.data
      end
    end
  end
end
