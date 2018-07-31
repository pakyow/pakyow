# frozen_string_literal: true

desc "Get help for the command line interface"
argument :command, "The command to get help for"
task :help, [:command] do |_, args|
  # FIXME: Without this condition the command runs infinitely. The reason isn't
  # obvious and needs to be revisited at some point in the future.
  #
  unless defined?($helping) && $helping
    $helping = true
    if args.key?(:command)
      Pakyow::CLI.new([args[:command], "-h"])
    else
      Pakyow::CLI.new(["-h"])
    end
  end
end
