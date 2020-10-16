# frozen_string_literal: true

require_relative "../generator"

command :create, global: true do
  describe "Create a new project"
  required :cli

  argument :path, "Where to create the project", required: true
  option :template, "The template to create the project from", default: "default"

  action do
    template = @template.downcase.strip
    generator = case template
    when "default"
      Pakyow.generator(:project)
    else
      Pakyow.generator(:project, template.to_sym)
    end

    generator.generate(@path, name: Generator.generatable_name(File.basename(@path)))

    require "pakyow/support/cli/style"
    @cli.feedback.puts <<~OUTPUT

      #{Pakyow::Support::CLI.style.bold "You're all set! Go to your new project:"}
    OUTPUT

    @cli.feedback.puts "  $ cd #{@path}"
    @cli.feedback.puts

    @cli.feedback.puts <<~OUTPUT
      #{Pakyow::Support::CLI.style.bold "Then boot it up:"}
    OUTPUT

    @cli.feedback.puts "  $ pakyow boot"
    @cli.feedback.puts
  end
end
