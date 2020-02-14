# frozen_string_literal: true

Pakyow.command :irb do
  describe "Start an interactive session"

  action do
    Pakyow.boot

    require "#{Pakyow.config.cli.repl.to_s.downcase}"

    ARGV.clear
    Pakyow.config.cli.repl.start
  end
end
