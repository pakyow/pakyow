# frozen_string_literal: true

command :irb do
  describe "Start an interactive session"

  action do
    Pakyow.boot

    require Pakyow.config.cli.repl.to_s.downcase.to_s

    ARGV.clear
    Pakyow.config.cli.repl.start
  end
end
