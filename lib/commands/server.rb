if ARGV.first == '--help' || ARGV.first == '-h'
  puts File.open(File.join(PAK_PATH, 'commands/USAGE-SERVER')).read
else
  $:.unshift(Dir.pwd)

  require 'app/setup'

  valid_args = true
  if port_arg = ARGV.index("-p")
  	if ARGV[port_arg + 1] =~ /^\d{1,5}$/
	  	Pakyow::Config.server.port = ARGV[port_arg + 1]
	  	ARGV.delete_at(port_arg + 1)
	  	ARGV.delete_at(port_arg)
	  else
	  	valid_args = false
	  end
  elsif port_arg = ARGV.index {|a| a =~ /^--port=\d{1,5}$/}
  	Pakyow::Config.server.port = ARGV[port_arg].gsub(/--port=/, '')
		ARGV.delete_at(port_arg)
  end

  if valid_args
	  Pakyow::App.run(ARGV.first)
	else
		puts File.open(File.join(PAK_PATH, 'commands/USAGE-SERVER')).read
	end
end
