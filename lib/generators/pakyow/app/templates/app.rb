require 'bundler/setup'

Pakyow::App.define do
  configure :development do
    # All development-specific configuration goes here.
  end

  configure :prototype do
    # An environment for running just the front-end prototype.
    app.ignore_routes = true
  end

  configure :production do
    # Alternate environments can be configured, like this one.
  end
end
