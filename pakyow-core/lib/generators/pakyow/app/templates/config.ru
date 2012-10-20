require File.expand_path('app', __FILE__)
PakyowApplication::Application.builder.run(PakyowApplication::Application.stage(ENV['RACK_ENV']))
run PakyowApplication::Application.builder.to_app
