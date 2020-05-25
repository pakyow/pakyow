# frozen_string_literal: true

# Requires bundle/setup.
#
if defined?(Bundler)
  Bundler.setup :default, Pakyow.env?(:prototype) ? :development : Pakyow.env
end
