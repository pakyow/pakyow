libdir = File.dirname(__FILE__)
$LOAD_PATH.unshift(libdir) unless $LOAD_PATH.include?(libdir)

# Gems
require 'mail'
require 'premailer'

# Base
require 'mailer/mailer'
require 'mailer/config/mailer'
require 'mailer/helpers'
require 'mailer/ext/premailer/adapter/oga'

Premailer::Adapter.use = :oga
