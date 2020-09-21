# frozen_string_literal: true

module Pakyow
  class Application
    module Helpers
      module Mailer
        def mailer(path = nil, &block)
          connection = @connection.dup
          mailer = app.mailer(path, __values: connection.values)

          if block_given?
            context = dup
            context.instance_variable_set(:@connection, connection)
            context.instance_exec(mailer, &block)
          end

          mailer
        end
      end
    end
  end
end
