module Pakyow
  Controller.before :error do
    logger.houston(req.error)
  end
end
