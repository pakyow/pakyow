require "pakyow/core"

Pakyow::App.define do
  configure do
    config.app.name = "example"
  end

  configure :development do
  end
end
