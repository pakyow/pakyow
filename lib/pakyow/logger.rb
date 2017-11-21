# frozen_string_literal: true

module Pakyow
  # Logging concerns for Pakyow apps
  #
  module Logger; end
end

require "pakyow/logger/colorizer"
require "pakyow/logger/multilog"
require "pakyow/logger/request_logger"
require "pakyow/logger/timekeeper"

require "pakyow/logger/formatters/dev"
require "pakyow/logger/formatters/logfmt"
