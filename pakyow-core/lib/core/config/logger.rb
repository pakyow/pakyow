Pakyow::Config.register :logger do |config|
  # whether or not pakyow should write to a log
  config.opt :enabled, true

  # the default level to log at
  config.opt :level, :debug

  # whether or not pakyow should log to stdout
  config.opt :stdout, true

  # where the log file should be placed
  config.opt :path, -> { File.join(Pakyow::Config.app.root, 'log') }

  # the name of the log file
  config.opt :filename, 'pakyow.log'

  # whether or not the log file should be synced
  config.opt :sync

  # whether or not the log file should be flushed automatically
  config.opt :auto_flush

  # whether or not the log file should be colorized
  config.opt :colorize
end.env :development do |opts|
  opts.sync = true
  opts.auto_flush = true
  opts.colorize = true
end.env :production do |opts|
  opts.sync = false
  opts.auto_flush = false
  opts.stdout = false
  opts.colorize = false
end
