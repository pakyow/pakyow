# frozen_string_literal: true

require "pakyow/routing"
require "pakyow/presenter"

require "pakyow/assets/framework"

module Pakyow
  config.commands.paths << File.expand_path("../commands", __FILE__)
end
