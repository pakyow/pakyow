# frozen_string_literal: true

command :prelaunch, :build, boot: false do
  describe "Run the build phase of the prelaunch sequence"
  required :cli

  action do
    Pakyow.setup

    Pakyow.commands.definitions.select { |command|
      command.prelaunch? && command.prelaunch_phase == :build
    }.each do |command|
      command.prelaunches do |**args|
        command.call(**global_options.merge(args))
      end
    end
  end

  private def global_options
    @global_options ||= {
      cli: @cli
    }.freeze
  end
end
