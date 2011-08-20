module Pakyow
  module Presenter
    autoload :PresenterBase,    'core/presenter_base'
    autoload :ViewLookupStore,  'presenter/view_lookup_store'
    autoload :View,             'presenter/view'
    autoload :LazyView,         'presenter/lazy_view'
    autoload :Binder,           'presenter/binder'
    autoload :Views,            'presenter/views'
    autoload :ViewContext,      'presenter/view_context'
  end
end
