require 'core/configuration/base'
require 'core/helpers'
require 'core/log'
require 'core/request'
require 'core/response'
require 'core/loader'
require 'core/routing'
require 'core/application'
require 'core/cache'
require 'core/presenter_base'

# middlewares
require 'core/middleware/logger'
require 'core/middleware/static'
require 'core/middleware/reloader'
require 'core/middleware/presenter'
require 'core/middleware/not_found'
require 'core/middleware/router'
require 'core/middleware/setup'

# utils
require 'utils/string'
require 'utils/hash'
require 'utils/dir'

module Pakyow
  attr_accessor :app
end
