# frozen_string_literal: true

require "pakyow/core/framework"

module Pakyow
  module Mailer
    class Framework < Pakyow::Framework(:mailer)
      def boot
        if controller = app.const_get(:Controller)
          controller.class_eval do
            def mailer(path)
              Mailer.new(view: Presenter::Renderer.new(@__state).setup(path).to_html, config: app.config.mailer)
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
