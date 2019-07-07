# frozen_string_literal: true

require "pakyow/routing"
require "pakyow/support"
require "pakyow/presenter"

require "pakyow/assets/framework"

require "pakyow/assets/types/js"
require "pakyow/assets/types/css"
require "pakyow/assets/types/sass"
require "pakyow/assets/types/scss"

require "pakyow/actions/assets/process"
require "pakyow/actions/assets/public"

module Pakyow
  config.tasks.paths << File.expand_path("../assets/tasks", __FILE__)
end
