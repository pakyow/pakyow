require 'pakyow/core/logger/formatters/dev_formatter'
require 'pakyow/core/logger/formatters/logfmt_formatter'

Pakyow::Config.register :logger do |config|
  # whether or not pakyow should write to a log
  config.opt :enabled, true

  # the default level to log at
  config.opt :level, :debug

  # the formatter responsible for formatting request logs
  config.opt :formatter, Pakyow::Logger::DevFormatter

  # where we should log to
  config.opt :destinations, -> do
    if Pakyow::Config.logger.enabled
      [$stdout]
    else
      ["/dev/null"]
    end
  end
end.env :test do |opts|
  opts.destinations = []
end.env :production do |opts|
  opts.formatter = Pakyow::Logger::LogfmtFormatter
  opts.level = :info
end
