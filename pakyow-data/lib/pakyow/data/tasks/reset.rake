# frozen_string_literal: true

require "pakyow/data/migrator"
require "pakyow/data/migrators/mysql"
require "pakyow/data/migrators/postgres"
require "pakyow/data/migrators/sqlite"

namespace :db do
  desc "Reset a database"
  option :adapter, "The adapter to migrate"
  option :connection, "The connection to migrate"
  task :reset, [:adapter, :connection] do |_, args|
    %w[
      db:drop
      db:bootstrap
    ].each do |task|
      Pakyow.logger.info "[db:reset] running: #{task}"
      Rake::Task[task].invoke(args[:adapter], args[:connection])
    end
  end
end
