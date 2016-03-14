require 'pakyow/core/helpers'
require 'pakyow/core/multilog'
require 'pakyow/core/app_context'
require 'pakyow/core/request'
require 'pakyow/core/response'
require 'pakyow/core/loader'
require 'pakyow/core/router'
require 'pakyow/core/route_merger'
require 'pakyow/core/route_module'
require 'pakyow/core/route_set'
require 'pakyow/core/route_eval'
require 'pakyow/core/route_expansion_eval'
require 'pakyow/core/route_template_eval'
require 'pakyow/core/route_template_defaults'
require 'pakyow/core/route_lookup'
require 'pakyow/core/app'
require 'pakyow/core/errors'

require 'pakyow/core/config'
require 'pakyow/core/config/reloader'
require 'pakyow/core/config/app'
require 'pakyow/core/config/server'
require 'pakyow/core/config/cookies'
require 'pakyow/core/config/logger'
require 'pakyow/core/config/session'

require 'pakyow/core/middleware/override'
require 'pakyow/core/middleware/reloader'
require 'pakyow/core/middleware/req_path_normalizer'
require 'pakyow/core/middleware/session'
require 'pakyow/core/middleware/static'
require 'pakyow/core/middleware/logger'

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

    logs << $stdout if Config.logger.stdout

    io = logs.count > 1 ? MultiLog.new(*logs) : logs[0]

    Pakyow.logger = Logger.new(io, Config.logger.level, Config.logger.colorize, Config.logger.auto_flush)
  end
end
