# frozen_string_literal: true

module Pakyow
  class Application
    module Helpers
      module UI
        def ui?
          @connection.request_header?("pw-ui")
        end

        def ui
          @connection.request_header("pw-ui")
        end

        # @api private
        def ui_transform?
          @connection.set?(:__ui_transform)
        end
      end
    end
  end
end
