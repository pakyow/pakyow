# frozen_string_literal: true

Pakyow.command :help do
  describe "Get help for the command line interface"
  required :cli

  argument :command, "The command to get help for"

  action do
    case @command
    when "help"
      @cli.usage(self.class)
    when nil
      @cli.help
    else
      @cli.usage(@command)
    end
  end
end
