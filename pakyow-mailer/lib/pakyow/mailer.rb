# frozen_string_literal: true

require "mail"

require "pakyow/support/silenceable"
Pakyow::Support::Silenceable.silence_warnings do
  require "premailer"
end

require "pakyow/core"
require "pakyow/presenter"

require "pakyow/mailer/extensions/app"
require "pakyow/mailer/extensions/controller"
require "pakyow/mailer/extensions/router"

require "pakyow/mailer/mailer"
require "pakyow/mailer/ext/premailer/adapter/oga"

Premailer::Adapter.use = :oga
