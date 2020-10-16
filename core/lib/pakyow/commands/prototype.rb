# frozen_string_literal: true

command :prototype do
  describe "Boot the prototype"

  option :host, "The host the server runs on", default: -> { Pakyow.config.runnable.server.host }
  option :port, "The port the server runs on", default: -> { Pakyow.config.runnable.server.port }

  action do
    Pakyow.config.runnable.server.host = @host
    Pakyow.config.runnable.server.port = @port
    Pakyow.run
  end
end
