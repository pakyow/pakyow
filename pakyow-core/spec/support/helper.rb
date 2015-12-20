require 'spec_helper'

require 'pakyow-support'
require 'pakyow-core'

# load spec helpers
Dir[File.join(File.dirname(__FILE__), 'helpers', '**', '*.rb')].each do |file|
  require file
end
