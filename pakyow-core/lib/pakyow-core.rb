libdir = File.dirname(__FILE__)
$LOAD_PATH.unshift(libdir) unless $LOAD_PATH.include?(libdir)

# Gems 
require 'find'
require 'rack'
require 'rack/file'
require 'logger'
require 'cgi'

# Base
autoload :Pakyow, 'core/base'

include Pakyow
