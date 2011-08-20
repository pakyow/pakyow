module Pakyow
  autoload :Configuration,  'core/configuration/base'
  autoload :Helpers,        'core/helpers'
  autoload :GeneralHelpers, 'core/helpers'
  autoload :Log,            'core/log'
  autoload :Request,        'core/request'
  autoload :Loader,         'core/loader'
  autoload :Application,    'core/application'
  autoload :RouteStore,    'core/route_store'

  # utils
  autoload :StringUtils,    'utils/string'
  autoload :HashUtils,      'utils/hash'
  autoload :DirUtils,       'utils/dir'

  attr_accessor :app
end
