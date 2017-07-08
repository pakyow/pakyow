# TODO: refactor to be on the Presenter object
Pakyow::App.settings_for :presenter do
  setting :path do
    File.join(config.app.root, "app", "presentation")
  end

  # if true, views are visible without a route defined
  setting :require_route, true

  defaults :prototype do
    setting :require_route, false
  end
end
