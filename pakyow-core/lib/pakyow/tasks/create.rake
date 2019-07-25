# frozen_string_literal: true

desc "Create a new project"
argument :path, "Where to create the project", required: true
option :template, "The template to create the project from"
global_task :create, [:path, :template] do |_, args|
  require "pakyow/support/inflector"

  project_name = Pakyow::Support.inflector.underscore(
    File.basename(args[:path]).downcase
  )

  project_name.gsub!("  ", " ")
  project_name.gsub!(" ", "_")

  human_project_name = Pakyow::Support.inflector.humanize(project_name)

  generator = if args.key?(:template)
    template = args[:template].downcase.strip
    require "pakyow/generators/project/#{template}"
    Pakyow::Generators::Project.const_get(Pakyow::Support.inflector.classify(template)).new(
      File.expand_path("../../generators/project/#{template}", __FILE__)
    )
  else
    require "pakyow/generators/project"
    Pakyow::Generators::Project.new(
      File.expand_path("../../generators/project/default", __FILE__)
    )
  end

  generator.generate(
    args[:path],
    project_name: project_name,
    human_project_name: human_project_name
  )

  require "pakyow/support/cli/style"
  puts <<~OUTPUT

    #{Pakyow::Support::CLI.style.bold "You're all set! Go to your new project:"}
      $ cd #{args[:path]}

    #{Pakyow::Support::CLI.style.bold "Then boot it up:"}
      $ pakyow boot

  OUTPUT
end
