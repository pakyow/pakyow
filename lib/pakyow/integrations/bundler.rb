# Requires gems for the current environment.
#
Pakyow.after :configure do
  Bundler.require :default, Pakyow.env
end
