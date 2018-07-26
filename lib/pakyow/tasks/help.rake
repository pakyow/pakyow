# frozen_string_literal: true

desc "Get help for the command line interface"
task :help, [:command] do |_, _args|
  # TODO: present help for a command, or global if no command
  #   we also need to handle the command being invalid
  pp self
end
