Pakyow::Config.register :session do |config|
  # whether or not to use sessions
  config.opt :enabled, true

  # the session object
  config.opt :object, Rack::Session::Cookie

  # session middleware config options
  config.opt :options, -> {
    opts = {
      key: Pakyow::Config.session.key,
      secret: Pakyow::Config.session.secret
    }

    # set optional options if available
    %i(domain path expire_after old_secret).each do |opt|
      value = Pakyow::Config.session.send(opt)
      opts[opt] = value if value
    end

    opts
  }

  # the session key
  config.opt :key, -> { "#{Pakyow::Config.app.name}.session" }

  # the session secret
  config.opt :secret, -> { ENV['SESSION_SECRET'] }

  # the old session secret (used for rotation)
  config.opt :old_secret

  # session expiration, in seconds
  config.opt :expire_after

  # session cookie path
  config.opt :path

  # session cookie domain
  config.opt :domain
end
