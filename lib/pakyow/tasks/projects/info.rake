# frozen_string_literal: true

require "pakyow/info"

require "pakyow/support/inflector"
require "pakyow/support/cli/style"

namespace :projects do
  desc "Show details about the current project"
  task :info do
    info = Pakyow.info
    longest_key_length = info.values.flat_map { |value|
      value.is_a?(Hash) ? value.keys : value
    }.max_by(&:length).length

    puts Pakyow::Support::CLI.style.bold("Library Versions".upcase)
    info[:versions].each do |key, value|
      puts "  #{Pakyow::Support.inflector.humanize(key).ljust(longest_key_length + 8)}#{value}"
    end

    puts
    info[:apps].each do |app|
      puts Pakyow::Support::CLI.style.bold(app[:class])
      app.delete(:class)
      app.each do |key, value|
        puts "  #{Pakyow::Support.inflector.humanize(key).ljust(longest_key_length + 8)}#{value}"
      end
    end
  end
end
