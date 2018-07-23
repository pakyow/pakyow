# frozen_string_literal: true

require "pakyow/data/migrator"
require "pakyow/data/migrators/mysql"
require "pakyow/data/migrators/postgres"
require "pakyow/data/migrators/sqlite"

namespace :db do
  desc "Setup a database"
  task :setup, [:adapter, :connection] do |_, args|
    %w[
      db:create
      db:migrate
    ].each do |task|
      Rake::Task[task].invoke(args[:adapter], args[:connection])
    end
  end
end
