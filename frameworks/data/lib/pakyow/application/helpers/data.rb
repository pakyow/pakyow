# frozen_string_literal: true

module Pakyow
  class Application
    module Helpers
      module Data
        def data
          @connection.app.data
        end
      end
    end
  end
end
