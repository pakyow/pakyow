# frozen_string_literal: true

module Pakyow
  class App
    module Helpers
      module Data
        def data
          @connection.app.data
        end
      end
    end
  end
end
