require "pakyow/all"

Pakyow::App.define do
  configure do
    app.name = "example"
  end

  configure :development do
  end
end
