# frozen_string_literal: true

require "pakyow/data/migrator"

namespace :db do
  desc "Bootstrap a database"
  option :adapter, "The adapter to migrate"
  option :connection, "The connection to migrate"
  task :bootstrap, [:adapter, :connection] do |_, args|
    tasks = %w[
      db:create
    ]

    if Pakyow.config.data.auto_migrate
      Pakyow.logger.warn "[db:bootstrap] skipped: db:migrate (because auto migrate is enabled)"
    else
      tasks << "db:migrate"
    end

    tasks.each do |task|
      Pakyow.logger.info "[db:bootstrap] running: #{task}"
      Rake::Task[task].invoke(args[:adapter], args[:connection])
    end
  end
end
