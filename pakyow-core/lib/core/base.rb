require 'core/config/base'
require 'core/config/app'
require 'core/config/server'
require 'core/config/cookies'
require 'core/config/logger'
require 'core/helpers'
require 'core/multilog'
require 'core/context'
require 'core/request'
require 'core/response'
require 'core/loader'
require 'core/router'
require 'core/route_merger'
require 'core/route_module'
require 'core/route_set'
require 'core/route_eval'
require 'core/route_template_defaults'
require 'core/route_lookup'
require 'core/app'
require 'core/errors'

# middlewares
require 'core/middleware/logger'
require 'core/middleware/static'
require 'core/middleware/reloader'

# utils
require 'utils/string'
require 'utils/hash'
require 'utils/dir'

module Pakyow
  attr_accessor :app, :logger

  def configure_logger
    conf = Config::Base

    logs = []

    if File.directory?(conf.logger.path)
      log_path = File.join(conf.logger.path, conf.logger.name)

      begin
        log = File.open(log_path, 'a')
        log.sync if conf.logger.sync

        logs << log
      rescue StandardError => e
        warn "Error opening '#{log_path}' for writing"
      end
    end

    logs << $stdout if conf.app.log_output

    io = logs.count > 1 ? MultiLog.new(*logs) : logs[0]

    Pakyow.logger = Logger.new(io, conf.logger.level, conf.logger.colorize, conf.logger.auto_flush)
  end
end
