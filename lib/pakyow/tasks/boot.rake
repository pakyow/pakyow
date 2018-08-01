# frozen_string_literal: true

require "pakyow/server"

desc "Boot the project server"
option :host, "The host the server runs on (default: #{Pakyow.config.server.host})"
option :port, "The port the server runs on (default: #{Pakyow.config.server.port})"
flag :standalone, "Disable automatic reloading of changes"
task :boot, [:host, :port, :standalone] do |_, args|
  Pakyow::Server.new(
    host: args[:host], port: args[:port],
    standalone: args[:standalone] || Pakyow.env?(:production)
  ).run
end
