require "pakyow/commands/console"

if ARGV.first == '--help' || ARGV.first == '-h'
  puts File.open(File.join(PAK_PATH, 'commands/USAGE-CONSOLE')).read
else
  Pakyow::Commands::Console
    .new(environment: ARGV.first)
    .run
end
