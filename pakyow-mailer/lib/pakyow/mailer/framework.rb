# frozen_string_literal: true

require "pakyow/framework"

module Pakyow
  module Mailer
    class Framework < Pakyow::Framework(:mailer)
      def boot
        require_relative "../application/helpers/mailer"

        require_relative "mailer"

        object.class_eval do
          configurable :mailer do
            setting :default_sender, "Pakyow"
            setting :default_content_type, "text/html"
            setting :delivery_method, :sendmail
            setting :delivery_options, {}
            setting :encoding, "UTF-8"
            setting :silent, true

            defaults :development do
              setting :silent, false
            end

            defaults :test do
              setting :delivery_method, :test
            end
          end

          register_helper :active, Pakyow::Application::Helpers::Mailer

          mail_renderer = Class.new(isolated(:Renderer)) do
            # Override so we don't trigger any hooks.
            #
            def perform(output = String.new)
              @presenter.to_html(output)
            end
          end

          # Delete the create_template_nodes build step since we don't want to mail templates.
          #
          mail_renderer.__build_fns.delete_if { |fn|
            fn.source_location[0].end_with?("create_template_nodes.rb")
          }

          isolate(mail_renderer, as: "MailRenderer")

          def mailer(path = nil, presentables)
            if path
              renderer = isolated(:MailRenderer).new(
                app: self,
                presentables: presentables,
                presenter_class: isolated(:MailRenderer).find_presenter(self, path),
                composer: Presenter::Composers::View.new(path, app: self)
              )

              Mailer.new(
                renderer: renderer,
                config: config.mailer,
                logger: Pakyow.logger
              )
            else
              Mailer.new(
                config: config.mailer,
                logger: Pakyow.logger
              )
            end
          end
        end
      end
    end
  end
end
