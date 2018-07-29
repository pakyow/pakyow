# frozen_string_literal: true

desc "Boot the project server"
task :boot do
  require "pakyow/server"

  # TODO: accept these arguments...
  # port: nil, host: nil, server: nil, standalone: false

  server = Pakyow::Server.new(standalone: Pakyow.env?(:production))
  server.run
end
