Pakyow::Config.register :logger do |config|
  # the default level to log at
  config.opt :level, :debug

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
  opts.colorize = false
end
