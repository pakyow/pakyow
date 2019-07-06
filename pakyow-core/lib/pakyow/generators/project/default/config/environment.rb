Pakyow.configure do
  # Global environment configuration.
end

Pakyow.configure :development do
  config.data.connections.sql[:default] = "sqlite://database/development.db"
end

Pakyow.configure :prototype do
  config.data.connections.sql[:default] = "sqlite://database/prototype.db"
end

Pakyow.configure :production do
  config.data.connections.sql[:default] = ENV["DATABASE_URL"]
end
