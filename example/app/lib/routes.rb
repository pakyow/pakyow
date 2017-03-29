Pakyow::App.router do
  default do
    logger.info 'hello ' + Time.now.to_s
  end
end
