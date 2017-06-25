# TODO: refactor to be on the Presenter object
Pakyow::App.settings_for :presenter do
  setting :path do
    File.join(config.app.root, "app", "views")
  end

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
