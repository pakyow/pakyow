libdir = File.dirname(__FILE__)
$LOAD_PATH.unshift(libdir) unless $LOAD_PATH.include?(libdir)

# Gems
require 'mail'
require 'premailer'

# Base
require 'pakyow/mailer/mailer'
require 'pakyow/mailer/config/mailer'
require 'pakyow/mailer/helpers'
require 'pakyow/mailer/ext/premailer/adapter/oga'

Premailer::Adapter.use = :oga
