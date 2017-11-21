# frozen_string_literal: true

# Requires gems for the current environment.
#
Pakyow.before :configure do
  Bundler.require :default, Pakyow.env
end
