require "logger"

require "pakyow/support/configurable"
require "pakyow/logger/formatters/dev_formatter"
require "pakyow/logger/formatters/logfmt_formatter"

module Pakyow
  DEFAULT_ENV    = :development
  DEFAULT_PORT   = 3000
  DEFAULT_HOST   = "localhost".freeze
  DEFAULT_SERVER = :puma

  include Support::Configurable

  settings_for :env do
    setting :default, DEFAULT_ENV
  end

  settings_for :server do
    setting :port, DEFAULT_PORT
    setting :host, DEFAULT_HOST
  end

  settings_for :logger do
    setting :enabled, true
    setting :level, :debug
    setting :formatter, Logger::DevFormatter

    setting :destinations do
      if config.logger.enabled
        [$stdout]
      else
        ["/dev/null"]
      end
    end

    defaults :test do
      setting :destinations, []
    end

    defaults :production do
      setting :level, :info
      setting :formatter, Logger::LogfmtFormatter
    end
  end
end
