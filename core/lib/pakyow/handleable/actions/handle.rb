# frozen_string_literal: true

module Pakyow
  module Handleable
    module Actions
      class Handle
        def call(connection)
          connection.handling(connection: connection) do
            yield
          rescue => error
            connection.error = error
            raise error
          end
        rescue => error
          Pakyow.houston(error)
          connection.trigger 500
        end
      end
    end
  end
end
