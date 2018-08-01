require "bundler/setup"

require "pakyow"
require "pakyow/all"

require "pakyow/integrations/bundler"
require "pakyow/integrations/dotenv"

Pakyow.configure do
  require "./config/application"
end

Pakyow.configure :development do
  config.data.connections.sql[:default] = "sqlite:///database/development.db"
end

Pakyow.configure :production do
  config.data.connections.sql[:default] = ENV["DATABASE_URL"]
end
