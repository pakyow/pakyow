# frozen_string_literal: true

command :boot, boot: false do
  describe "Boot the project"

  option :host, "The host the server runs on", default: -> { Pakyow.config.runnable.server.host }
  option :port, "The port the server runs on", default: -> { Pakyow.config.runnable.server.port }

  option :formation, "The formation to boot", default: -> { Pakyow.config.runnable.formation }

  option :mounts, "The application(s) to mount", default: -> { Pakyow.config.mounts }

  action do
    Pakyow.config.mounts = case @mounts
    when String
      @mounts.split(",").map(&:to_sym)
    else
      @mounts
    end

    Pakyow.config.runnable.server.host = @host
    Pakyow.config.runnable.server.port = @port

    require "pakyow/runnable/formation"
    Pakyow.run(env: @env, formation: Pakyow::Runnable::Formation.parse(@formation))
  end
end
