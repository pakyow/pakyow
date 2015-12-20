Pakyow::Config.register(:logger) { |config|

  # the default level to log at
  config.opt :level, :debug

  # where the log file should be placed
  config.opt :path, lambda { File.join(Pakyow::Config.app.root, 'log') }

  # the name of the log file
  config.opt :filename, 'pakyow.log'

  # whether or not the log file should be synced
  config.opt :sync

  # whether or not the log file should be flushed automatically
  config.opt :auto_flush

  # whether or not the log file should be colorized
  config.opt :colorize

}.env(:development) { |opts|

  opts.sync = true
  opts.auto_flush = true
  opts.colorize = true

}.env(:production) { |opts|

  opts.sync = false
  opts.auto_flush = false
  opts.colorize = false

}
