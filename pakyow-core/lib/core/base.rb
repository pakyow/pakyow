require 'core/helpers'
require 'core/multilog'
require 'core/app_context'
require 'core/request'
require 'core/response'
require 'core/loader'
require 'core/router'
require 'core/route_merger'
require 'core/route_module'
require 'core/route_set'
require 'core/route_eval'
require 'core/route_expansion_eval'
require 'core/route_template_eval'
require 'core/route_template_defaults'
require 'core/route_lookup'
require 'core/app'
require 'core/errors'
require 'core/config'
require 'core/config/reloader'
require 'core/config/app'
require 'core/config/server'
require 'core/config/cookies'
require 'core/config/logger'

# middlewares
require 'core/middleware/logger'
require 'core/middleware/static'
require 'core/middleware/reloader'

module Pakyow
  class << self
    attr_accessor :app, :logger
  end

  def self.configure_logger
    logs = []

    if File.directory?(Config.logger.path)
      log_path = File.join(Config.logger.path, Config.logger.filename)

      begin
        log = File.open(log_path, 'a')
        log.sync if Config.logger.sync

        logs << log
      rescue StandardError => e
        warn "Error opening '#{log_path}' for writing"
      end
    end

    logs << $stdout if Config.app.log_output

    io = logs.count > 1 ? MultiLog.new(*logs) : logs[0]

    Pakyow.logger = Logger.new(io, Config.logger.level, Config.logger.colorize, Config.logger.auto_flush)
  end
end
