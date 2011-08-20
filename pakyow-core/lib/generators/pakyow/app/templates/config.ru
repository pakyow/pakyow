require 'config/application'
PakyowApplication::Application.stage(:development)

app = Rack::Builder.new do
  # Needed for Pakyow to work
  use Rack::MethodOverride
  run PakyowApplication::Application.new
end.to_app

run(app)
