# frozen_string_literal: true

require "pakyow/framework"

require "pakyow/mailer/mailer"
require "pakyow/mailer/helpers"

module Pakyow
  module Mailer
    class Framework < Pakyow::Framework(:mailer)
      def boot
        app.class_eval do
          subclass :Controller do
            include Helpers
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
