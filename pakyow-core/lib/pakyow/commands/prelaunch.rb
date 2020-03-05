# frozen_string_literal: true

command :prelaunch do
  describe "Run all phases of the prelaunch sequence"
  required :cli

  action do
    require "pakyow/support/deprecator"

    # Run prelaunch commands registered with the environment.
    #
    each_command(Pakyow) do |command, options|
      @cli.call(command, **options)
    end

    # Run prelaunch commands registered with each pakyow app.
    #
    Pakyow.apps.each do |app|
      each_command(app) do |command, options|
        options[:app] = app

        @cli.call(command, **options)
      end
    end

    %w(prelaunch:build prelaunch:release).each do |command|
      @cli.call(command)
    end
  end

  private def each_command(object)
    Pakyow::Support::Deprecator.global.ignore do
      (object.config.tasks.prelaunch).uniq.each do |command, options = {}|
        yield command, options.merge(global_options)
      end
    end
  end

  private def global_options
    @global_options ||= {
      cli: @cli
    }
  end
end
