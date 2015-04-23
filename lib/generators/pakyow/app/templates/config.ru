require File.expand_path('../pakyow', __FILE__)

app = Pakyow::App
app.builder.run(app.stage(ENV['APP_ENV'] || ENV['RACK_ENV']))
run app.builder.to_app
