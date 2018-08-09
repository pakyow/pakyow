# frozen_string_literal: true

require "pakyow/framework"

require "pakyow/mailer/mailer"

module Pakyow
  module Mailer
    class Framework < Pakyow::Framework(:mailer)
      def boot
        app.class_eval do
          subclass? :Controller do
            def mailer(path = nil)
              if path
                connection = @connection.dup

                renderer = @connection.app.subclass(:Renderer).new(
                  connection,
                  path: path,
                  templates: false
                )

                Mailer.new(
                  renderer: renderer,
                  config: app.config.mailer,
                  logger: @connection.logger
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

          settings_for :mailer do
            setting :default_sender, "Pakyow"
            setting :default_content_type, "text/html"
            setting :delivery_method, :sendmail
            setting :delivery_options, {}
            setting :encoding, "UTF-8"
            setting :silent, true

            defaults :development do
              setting :silent, false
            end
          end
        end
      end
    end
  end
end
