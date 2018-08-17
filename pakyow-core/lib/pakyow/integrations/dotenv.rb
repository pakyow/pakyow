# frozen_string_literal: true

# Loads environment variables.
#
if defined?(Dotenv)
  env_path = ".env.#{Pakyow.env}"
  Dotenv.load env_path if File.exist?(env_path)
  Dotenv.load
end
