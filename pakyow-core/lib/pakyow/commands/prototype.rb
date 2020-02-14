# frozen_string_literal: true

Pakyow.command :prototype do
  describe "Boot the prototype"

  option :host, "The host the server runs on", default: -> { Pakyow.config.server.host }
  option :port, "The port the server runs on", default: -> { Pakyow.config.server.port }

  action do
    Pakyow.config.server.host = @host
    Pakyow.config.server.port = @port
    Pakyow.run
  end
end
