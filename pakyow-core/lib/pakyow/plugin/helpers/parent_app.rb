# frozen_string_literal: true

module Pakyow
  class Plugin
    module Helpers
      module ParentApp
        def parent_app
          @connection.app.app
        end
      end
    end
  end
end
