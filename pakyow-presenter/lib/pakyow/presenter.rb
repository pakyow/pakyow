require 'pakyow/support/silenceable'

Pakyow::Support::Silenceable.silence_warnings do
  require 'oga'
end

require 'pakyow/presenter/base'
require 'pakyow/presenter/presenter'
require 'pakyow/presenter/config/presenter'
require 'pakyow/presenter/helpers'
require 'pakyow/presenter/ext/app'
