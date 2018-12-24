# frozen_string_literal: true

require "pakyow"
require "pakyow/routing"

require "pakyow/data/connection"

Pakyow::Data::Connection.register_adapter :sql

require "pakyow/data/errors"
require "pakyow/data/framework"

require "pakyow/environment/data/auto_migrate"
require "pakyow/environment/data/config"
require "pakyow/environment/data/connections"
require "pakyow/environment/data/forking"
require "pakyow/environment/data/memory_db"

module Pakyow
  config.tasks.paths << File.expand_path("../data/tasks", __FILE__)

  include Environment::Data::AutoMigrate
  include Environment::Data::Config
  include Environment::Data::Connections
  include Environment::Data::Forking
  include Environment::Data::MemoryDB
end
