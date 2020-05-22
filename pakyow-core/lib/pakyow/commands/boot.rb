# frozen_string_literal: true

require "pakyow/support/deprecatable"

command :boot, boot: false do
  describe "Boot the project"

  option :host, "The host the server runs on", default: -> { Pakyow.config.runnable.server.host }
  option :port, "The port the server runs on", default: -> { Pakyow.config.runnable.server.port }

  option :formation, "The formation to boot", default: -> { Pakyow.config.runnable.formation }

  flag :standalone, nil
  extend Pakyow::Support::Deprecatable
  deprecate :standalone

  verify do
    optional :env
  end

  action do
    Pakyow.config.runnable.server.host = @host
    Pakyow.config.runnable.server.port = @port

    if @standalone
      Pakyow.config.runnable.watcher.enabled = false
    end

    require "pakyow/runnable/formation"
    Pakyow.run(env: @env, formation: Pakyow::Runnable::Formation.parse(@formation))
  end
end
