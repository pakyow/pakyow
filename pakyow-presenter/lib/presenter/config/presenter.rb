Pakyow::Config.register :presenter do |config|
  # registered view stores
  config.opt :view_stores, -> {
    @stores ||= {
      default: File.join(Pakyow::Config.app.root, 'app', 'views')
    }
  }

  # the default view for each view store
  config.opt :default_views, { default: :default }

  # a convenience option to lookup the default_view for a view store by name
  config.opt :default_view, -> (store_name) {
    views = Pakyow::Config.presenter.default_views
    views.fetch(store_name) { views[:default] }
  }

  # the default template dir for each view store
  config.opt :template_dirs, { default: '_templates' }

  # a convenience option to lookup the template_dir for a view store by name
  config.opt :template_dir, -> (store_name) {
    dirs = Pakyow::Config.presenter.template_dirs
    dirs.fetch(store_name) { dirs[:default] }
  }

  # the attribute expected for scope definitions
  config.opt :scope_attribute, 'data-scope'

  # the attribute expected for prop definitions
  config.opt :prop_attribute, 'data-prop'

  # if true, views are visible without a route defined
  config.opt :require_route, true

  # the document class used to parse and render views
  config.opt :view_doc_class, Pakyow::Presenter::StringDoc
end.env :development do |opts|
  opts.require_route = false
end.env :production do |opts|
  opts.require_route = true
end
