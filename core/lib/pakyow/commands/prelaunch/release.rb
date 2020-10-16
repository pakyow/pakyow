# frozen_string_literal: true

command :prelaunch, :release do
  describe "Run the release phase of the prelaunch sequence"
  required :cli

  action do
    Pakyow.commands.definitions.select { |command|
      command.prelaunch? && command.prelaunch_phase == :release
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
