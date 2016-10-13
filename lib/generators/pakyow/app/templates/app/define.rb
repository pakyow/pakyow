require "pakyow/all"

Pakyow::App.define do
  configure do
    app.name = '<%= app_name %>'
  end

  configure :development do
    # development config goes here
  end

  configure :production do
    # production config goes here
  end
end
