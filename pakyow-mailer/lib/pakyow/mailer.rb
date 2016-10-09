require 'mail'

require "pakyow/support/silenceable"
Pakyow::Support::Silenceable.silence_warnings do
  require "premailer"
end

require 'pakyow/mailer/mailer'
require 'pakyow/mailer/config/mailer'
require 'pakyow/mailer/helpers'
require 'pakyow/mailer/ext/premailer/adapter/oga'

Premailer::Adapter.use = :oga
