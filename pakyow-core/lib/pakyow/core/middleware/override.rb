Pakyow::App.middleware do |builder|
  builder.use Rack::MethodOverride
end
