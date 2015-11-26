builder.use Rack::Session::Cookie, key: "#{Pakyow::Config.app.name}.session", secret: ENV['SESSION_SECRET']
