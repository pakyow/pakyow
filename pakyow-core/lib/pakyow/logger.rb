# frozen_string_literal: true

require "logger"

module Pakyow
  class Logger < ::Logger
    require "pakyow/logger/colorizer"
    require "pakyow/logger/multilog"
    require "pakyow/logger/timekeeper"
  end
end
