# frozen_string_literal: true

desc "Boot the environment"
option :host, "The host the server runs on (default: #{Pakyow.config.server.host})"
option :port, "The port the server runs on (default: #{Pakyow.config.server.port})"
flag :standalone, "Disable automatic reloading of changes"
task :boot, [:host, :port, :standalone] do |_, args|
  if host = args[:host]
    Pakyow.config.server.host = host
  end

  if port = args[:port]
    Pakyow.config.server.port = port
  end

  if args[:standalone]
    Pakyow.config.server.proxy = false
  end

  Pakyow.run
end
