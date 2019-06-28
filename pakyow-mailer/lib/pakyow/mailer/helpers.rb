# frozen_string_literal: true

module Pakyow
  module Mailer
    module Helpers
      def mailer(path = nil)
        if path
          connection = @connection.dup

          renderer = connection.app.isolated(:MailRenderer).new(
            app: connection.app,
            presentables: connection.values,
            presenter_class: connection.app.isolated(:MailRenderer).find_presenter(connection.app, path),
            composer: Presenter::Composers::View.new(path, app: @connection.app)
          )

          Mailer.new(
            renderer: renderer,
            config: app.config.mailer,
            logger: connection.logger
          ).tap do |mailer|
            if block_given?
              context = dup
              context.instance_variable_set(:@connection, connection)
              context.instance_exec(mailer, &Proc.new)
            end
          end
        else
          Mailer.new(
            config: app.config.mailer,
            logger: @connection.logger
          )
        end
      end
    end
  end
end
