require 'bundler/setup'

Pakyow::App.define do
  configure :development do
    # All development-specific configuration goes here.
  end

  configure :production do
    # Alternate environments can be configured, like this one.
  end
end
