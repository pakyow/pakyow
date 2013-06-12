if ARGV.first == '--help' || ARGV.first == '-h'
  puts File.open(File.join(CORE_PATH, 'commands/USAGE-SERVER')).read
else
  $:.unshift(Dir.pwd)

  require 'app'

  valid_args = true
  ARGV.each_with_index {|arg, index|
  	if arg == "-p" || arg == "-port"
  		if ARGV[index + 1] =~ /^\d{1,5}$/
		  	Pakyow::Config::Server.port = ARGV[index + 1]
		  	2.times {ARGV.delete_at(index)}
		  else
		  	valid_args = false
		  end
	  end
  }

  if valid_args
	  Pakyow::App.run(ARGV.first)
	else
		puts File.open(File.join(CORE_PATH, 'commands/USAGE-SERVER')).read
	end
end
