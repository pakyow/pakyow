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
            Pakyow.houston(error)
            raise error
          end
        rescue
          connection.trigger 500
        end
      end
    end
  end
end
