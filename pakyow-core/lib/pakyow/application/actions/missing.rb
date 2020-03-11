# frozen_string_literal: true

module Pakyow
  class Application
    module Actions
      class Missing
        def call(connection)
          yield

          unless connection.halted? || connection.streaming?
            connection.trigger 404
          end
        end
      end
    end
  end
end
