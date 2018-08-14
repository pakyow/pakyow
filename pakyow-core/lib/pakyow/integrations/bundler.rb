# frozen_string_literal: true

# Requires the bundle.
#
Pakyow.before :configure do
  if defined?(Bundler)
    Bundler.require :default, Pakyow.env
  end
end
