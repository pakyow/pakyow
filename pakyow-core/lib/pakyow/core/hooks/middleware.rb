require "pakyow/core/middleware/static"

module Pakyow
  App.after :configure do
    if config.session.enabled
      builder.use config.session.object, config.session.options
    end

    if config.app.static
      builder.use Middleware::Static
    end
  end
end
