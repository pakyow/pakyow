require File.expand_path('../app', __FILE__)

app = Pakyow::App
app.builder.run(app.stage(ENV['RACK_ENV']))
run app.builder.to_app
