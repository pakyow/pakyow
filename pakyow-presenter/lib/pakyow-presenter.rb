libdir = File.dirname(__FILE__)
$LOAD_PATH.unshift(libdir) unless $LOAD_PATH.include?(libdir)

# Gems
require 'oga'

require 'pakyow/presenter/base'
require 'pakyow/presenter/presenter'
require 'pakyow/presenter/config/presenter'
require 'pakyow/presenter/helpers'
require 'pakyow/presenter/ext/app'
require 'pakyow/presenter/ext/call_context'
