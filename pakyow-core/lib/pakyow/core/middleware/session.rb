Pakyow::App.middleware do |builder|
  if Pakyow::Config.session.enabled
    builder.use Pakyow::Config.session.object, Pakyow::Config.session.options
  end
end
