Pakyow::App.routes do
  default do
    logger.info 'hello ' + Time.now.to_s
  end
end
