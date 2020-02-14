# frozen_string_literal: true

require "pakyow/info"

require "pakyow/support/inflector"
require "pakyow/support/cli/style"

Pakyow.command :info do
  describe "Show details about the current project"
  required :cli

  action do
    info = Pakyow.info
    longest_key_length = info.values.flat_map { |value|
      value.is_a?(Hash) ? value.keys : value
    }.max_by(&:length).length

    @cli.feedback.puts Pakyow::Support::CLI.style.bold("Library Versions".upcase)
    info[:versions].each do |key, value|
      @cli.feedback.puts "  #{Pakyow::Support.inflector.humanize(key).ljust(longest_key_length + 8)}#{value}"
    end

    info[:apps].each do |app|
      header = app[:class]
      header += " [#{app[:reference]}]" if app.key?(:reference)
      @cli.feedback.puts
      @cli.feedback.puts Pakyow::Support::CLI.style.bold(header)
      app.delete(:class)
      app.delete(:reference)
      app.each do |key, value|
        @cli.feedback.puts "  #{Pakyow::Support.inflector.humanize(key).ljust(longest_key_length + 8)}#{value}"
      end
    end
  end
end
