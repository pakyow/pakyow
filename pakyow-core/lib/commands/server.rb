if ARGV.first == '--help' || ARGV.first == '-h'
  puts File.open(File.join(CORE_PATH, 'commands/USAGE-SERVER')).read
else
  $:.unshift(Dir.pwd)

  require 'app'
  Pakyow::App.run(ARGV.first)
end
