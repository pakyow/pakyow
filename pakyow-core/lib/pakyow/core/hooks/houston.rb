module Pakyow
  App.after :error do
    logger.houston(req.error)
  end
end
