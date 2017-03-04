module Pakyow
  App.after :configure do
    if config.session.enabled
      builder.use config.session.object, config.session.options
    end
  end
end
