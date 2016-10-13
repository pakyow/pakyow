require "bundler/setup"
require "pakyow/integrations/bundler"
require "pakyow/integrations/dotenv"
require "./app/define"

Pakyow.configure do
  mount Pakyow::App, at: "/"
end
