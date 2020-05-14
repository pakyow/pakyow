# frozen_string_literal: true

command :boot, boot: false do
  describe "Boot the project"

  option :host, "The host the server runs on", default: -> { Pakyow.config.runnable.server.host }
  option :port, "The port the server runs on", default: -> { Pakyow.config.runnable.server.port }

  option :formation, "The formation to boot", default: -> { Pakyow.config.runnable.formation }

  flag :standalone, "Disable automatic reloading of changes"

  verify do
    optional :env
  end

  action do
    Pakyow.config.runnable.server.host = @host
    Pakyow.config.runnable.server.port = @port

    require "pakyow/runnable/formation"
    Pakyow.run(env: @env, formation: Pakyow::Runnable::Formation.parse(@formation))
  end
end
