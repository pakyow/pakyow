# frozen_string_literal: true

require "pakyow/core/framework"

require "pakyow/mailer/mailer"

module Pakyow
  module Mailer
    class Framework < Pakyow::Framework(:mailer)
      def boot
        if controller = app.const_get(:Controller)
          controller.class_eval do
            def mailer(path = nil)
              content = if path
                connection = @connection.dup

                renderer = Presenter::Renderer.new(
                  connection,
                  path: path,
                  templates: false
                )

                Mailer.new(renderer: renderer, config: app.config.mailer).tap do |mailer|
                  if block_given?
                    context = dup
                    context.instance_variable_set(:@connection, connection)
                    context.instance_exec(mailer, &Proc.new)
                  end
                end
              else
                Mailer.new(config: app.config.mailer)
              end
            end
          end
        end

        app.class_eval do
          settings_for :mailer do
            setting :default_sender, "Pakyow"
            setting :default_content_type do
              "text/html; charset=" + config.mailer.encoding
            end
            setting :delivery_method, :sendmail
            setting :delivery_options, enable_starttls_auto: false
            setting :encoding, "UTF-8"
          end
        end
      end
    end
  end
end
