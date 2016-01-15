require 'bundler/setup'
require 'pakyow'

Pakyow::App.define do
  configure :global do
    Bundler.require :default, Pakyow::Config.env

    if defined?(Dotenv)
      env_path = ".env.#{Pakyow::Config.env}"
      Dotenv.load env_path if File.exist?(env_path)
      Dotenv.load
    end

    # put global config here and they'll be available across environments
    app.name = '<%= app_name %>'
    logger.enabled = true
  end

  configure :development do
    # put development config here
  end

  configure :prototype do
    # an environment for running the front-end prototype with no backend
    app.ignore_routes = true
  end

  configure :production do
    # put your production config here
  end

  middleware do |builder|
    Dir.glob('middleware/*.rb').each { |r| require File.join('.', r) }
  end
end
