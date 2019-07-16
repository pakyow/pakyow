# frozen_string_literal: true

require "pakyow"
require "pakyow/routing"

require "pakyow/data/connection"

Pakyow::Data::Connection.register_adapter :sql

require "pakyow/data/errors"
require "pakyow/data/framework"

require "pakyow/behavior/data/auto_migrate"
require "pakyow/behavior/data/connections"
require "pakyow/behavior/data/memory_db"
require "pakyow/config/data"

require "pakyow/validations/data/unique"

module Pakyow
  config.tasks.paths << File.expand_path("../tasks", __FILE__)

  include Behavior::Data::AutoMigrate
  include Behavior::Data::Connections
  include Behavior::Data::MemoryDB
  include Config::Data
end
