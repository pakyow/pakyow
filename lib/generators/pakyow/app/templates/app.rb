require 'bundler/setup'

require 'pakyow'

Pakyow::App.define do
  configure :global do
    # put global config here and they'll be available across environments
  end

  configure :development do
    # put development config here
  end

  configure :prototype do
    # an environment for running the front-end prototype with no backend
    app.ignore_routes = true
  end

  configure :production do
    # suggested production configuration
    app.auto_reload = false
    app.errors_in_browser = false

    # put your production config here
  end
end
