# frozen_string_literal: true

module Pakyow
  class Application
    module Helpers
      module Mailer
        def mailer(path = nil)
          connection = @connection.dup
          mailer = app.mailer(path, connection.values)

          if block_given?
            context = dup
            context.instance_variable_set(:@connection, connection)
            context.instance_exec(mailer, &Proc.new)
          end

          mailer
        end
      end
    end
  end
end
