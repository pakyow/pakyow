# frozen_string_literal: true

desc "Get help for the command line interface"
argument :command, "The command to get help for"
task :help, [:command, :cli] do |_, args|
  if args.key?(:command)
    case args[:command]
    when "help"
      args[:cli].feedback.usage(self)
    else
      args[:cli].feedback.usage(args[:cli].find_task(args[:command]))
    end
  else
    args[:cli].feedback.help(args[:cli].tasks)
  end
end
