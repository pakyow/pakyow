# frozen_string_literal: true

require "pakyow/routing"
require "pakyow/presenter"

require_relative "assets/framework"
require_relative "behavior/assets/externals"

module Pakyow
  config.commands.paths << File.expand_path("../commands", __FILE__)

  include Behavior::Assets::Externals
end
