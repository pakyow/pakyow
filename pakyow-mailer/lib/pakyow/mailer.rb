require 'mail'
require 'premailer'

require 'pakyow/mailer/mailer'
require 'pakyow/mailer/config/mailer'
require 'pakyow/mailer/helpers'
require 'pakyow/mailer/ext/premailer/adapter/oga'

Premailer::Adapter.use = :oga
