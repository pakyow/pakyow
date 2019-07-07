# frozen_string_literal: true

require "pakyow/support"
require "pakyow/routing"
require "pakyow/presenter"

require "pakyow/realtime/framework"

require "pakyow/environment/realtime/config"

require "pakyow/actions/realtime/upgrader"

module Pakyow
  include Environment::Realtime::Config
end
