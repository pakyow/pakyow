# frozen_string_literal: true

module Pakyow
  class App
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
