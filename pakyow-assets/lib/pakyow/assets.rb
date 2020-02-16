# frozen_string_literal: true

require "pakyow/routing"
require "pakyow/support"
require "pakyow/presenter"

require "pakyow/assets/framework"

require "pakyow/application/actions/assets/process"
require "pakyow/application/actions/assets/public"

module Pakyow
  config.commands.paths << File.expand_path("../commands", __FILE__)
end
