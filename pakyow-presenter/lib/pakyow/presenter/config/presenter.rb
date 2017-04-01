Pakyow::App.settings_for :presenter do
  # registered view stores
  setting :view_stores do
    {
      default: File.join(config.app.root, "app", "views")
    }
  end

  # the default template dir for each view store
  setting :template_dirs, { default: "_templates" }

  # a convenience option to lookup the template_dir for a view store by name
  setting :template_dir, -> (store_name) {
    dirs = config.presenter.template_dirs
    dirs.fetch(store_name) { dirs[:default] }
  }

  # the attribute expected for scope definitions
  # TODO: this shouldn't be configurable
  setting :scope_attribute, "data-scope"

  # the attribute expected for prop definitions
  # TODO: this also shouldn't be configurable
  setting :prop_attribute, "data-prop"

  # if true, views are visible without a route defined
  # TODO: we should reconsider this difference between dev/prd
  #   and potentially handle this with a development-only handler for convenience
  setting :require_route, false

  # the document class used to parse and render views
  # TODO: we won't make this configurable
  setting :view_doc_class, Pakyow::Presenter::StringDoc

  defaults :test do
    setting :require_route, true
  end

  defaults :production do
    setting :require_route, true
  end
end
