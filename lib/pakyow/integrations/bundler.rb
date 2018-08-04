# frozen_string_literal: true

# Requires gems for the current environment.
#
Pakyow.before :configure do
  if defined?(Bundler)
    Bundler.require :default, Pakyow.env
  end
end
