module Pakyow
  Controller.after :route do
    next if app.config.presenter.require_route && !found?
    render
  end
end
