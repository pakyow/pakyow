# frozen_string_literal: true

require "pakyow/support/extension"

module Pakyow
  module Mailer
    module Behavior
      module Config
        extend Support::Extension

        apply_extension do
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
          end
        end
      end
    end
  end
end
