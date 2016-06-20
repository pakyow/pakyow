Pakyow::Config.register :server do |config|
  # the port to start `pakyow server`
  config.opt :port, 3000

  # the host to start `pakyow server`
  config.opt :host, 'localhost'

  # explicitly set a handler to try (e.g. puma)
  config.opt :handler
end
