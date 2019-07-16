# frozen_string_literal: true

require "pakyow/support"
require "pakyow/routing"
require "pakyow/presenter"

require "pakyow/realtime/framework"

require "pakyow/config/realtime"

require "pakyow/application/actions/realtime/upgrader"

module Pakyow
  include Config::Realtime
end
