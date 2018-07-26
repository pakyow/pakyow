# frozen_string_literal: true

desc "Run the prelaunch tasks"
task :prelaunch, [:app] do |_, args|
  # TODO: implement

  # %w(
  #   db:migrate
  #   assets:precompile
  #   docs:guides
  # ).each { |task|
  #   puts "invoking #{task}"

  #   Rake::Task[task].invoke(*Hash[args.select { |key, value|
  #     Rake::Task[task].arg_names.include?(key)
  #   }].values)
  # }
end
