if ARGV.first == '--help' || ARGV.first == '-h'
  puts File.open(File.join(CORE_PATH, 'commands/USAGE-SERVER')).read
else
  $:.unshift(Dir.pwd)

  require 'app'
  PakyowApplication::Application.run(ARGV.first)
end
