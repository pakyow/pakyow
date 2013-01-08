require 'core/configuration/base'
require 'core/helpers'
require 'core/log'
require 'core/request'
require 'core/response'
require 'core/loader'
require 'core/router'
require 'core/route_set'
require 'core/route_template'
require 'core/route_template_defaults'
require 'core/route_lookup'
require 'core/application'
require 'core/cache'
require 'core/presenter_base'
require 'core/fn_context'

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
