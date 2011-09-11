libdir = File.dirname(__FILE__)
$LOAD_PATH.unshift(libdir) unless $LOAD_PATH.include?(libdir)

# Gems 
require 'mail'

# Base
require 'mailer/mailer'
require 'mailer/configuration/base'
