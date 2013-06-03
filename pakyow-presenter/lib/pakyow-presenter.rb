libdir = File.dirname(__FILE__)
$LOAD_PATH.unshift(libdir) unless $LOAD_PATH.include?(libdir)

# Gems 
require 'nokogiri'

# Base
require 'presenter/base'
include Presenter

require 'presenter/presenter'
require 'presenter/config/base'
require 'presenter/helpers'
require 'presenter/ext/app'
