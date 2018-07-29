# frozen_string_literal: true

namespace :projects do
  desc "Create a new project"
  argument :path, "Where to create the project", required: true
  global_task :create, [:path] do |_, args|
    project_name = File.basename(args[:path])

    require "pakyow/generators/project"
    Pakyow::Generators::Project.new(
      File.expand_path("../../../generators/project/default", __FILE__)
    ).generate(args[:path], project_name: project_name)

    require "pakyow/support/cli/style"
    puts <<~OUTPUT
      #{Pakyow::Support::CLI.style.bold "You're all set! Go to your new project:"}
        $ cd #{args[:path]}

      #{Pakyow::Support::CLI.style.bold "Then boot it up:"}
        $ pakyow boot

    OUTPUT
  end
end
