# frozen_string_literal: true

require "pakyow/framework"

require "pakyow/application/config/mailer"
require "pakyow/application/helpers/mailer"

module Pakyow
  module Mailer
    class Framework < Pakyow::Framework(:mailer)
      def boot
        object.class_eval do
          include Pakyow::Application::Config::Mailer

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

          unless const_defined?(:MailRenderer, false)
            const_set(:MailRenderer, mail_renderer)
          end

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
