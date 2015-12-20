libdir = File.dirname(__FILE__)
$LOAD_PATH.unshift(libdir) unless $LOAD_PATH.include?(libdir)

# Gems
require 'nokogiri'

require 'presenter/base'
require 'presenter/presenter'
require 'presenter/config/presenter'
require 'presenter/helpers'
require 'presenter/ext/app'
require 'presenter/ext/call_context'
