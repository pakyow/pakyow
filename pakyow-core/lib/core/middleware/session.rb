Pakyow::App.middleware do |builder|
  if Pakyow::Config.session.enabled
    builder.use Pakyow::Config.session.object, key: Pakyow::Config.session.key, secret: Pakyow::Config.session.secret
  end
end
