# frozen_string_literal: true

# Requires the bundle.
#
if defined?(Bundler)
  Bundler.require :default, Pakyow.env?(:prototype) ? :development : Pakyow.env
end
