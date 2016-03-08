Pakyow::Config.register :mailer do |config|
  # the default sender name
  config.opt :default_sender, 'Pakyow'

  # the default mimetype to use
  config.opt :default_content_type, -> { 'text/html; charset=' + Pakyow::Config.mailer.encoding }

  # the delivery method to use for sending mail
  config.opt :delivery_method, :sendmail

  # any delivery options necessary for `delivery_method`
  config.opt :delivery_options, { enable_starttls_auto: false }

  # the default encoding to use
  config.opt :encoding, 'UTF-8'
end
