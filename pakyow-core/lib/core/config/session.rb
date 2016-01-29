Pakyow::Config.register :session do |config|
  # whether or not to use sessions
  config.opt :enabled, true

  # the session object
  config.opt :object, Rack::Session::Cookie

  # the session key
  config.opt :key, -> { "#{Pakyow::Config.app.name}.session" }

  # the session secret
  config.opt :secret, -> { ENV['SESSION_SECRET'] }
end
