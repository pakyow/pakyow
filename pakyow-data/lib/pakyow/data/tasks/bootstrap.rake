# frozen_string_literal: true

require "pakyow/data/migrator"

namespace :db do
  desc "Bootstrap a database"
  option :adapter, "The adapter to migrate"
  option :connection, "The connection to migrate"
  task :bootstrap, [:adapter, :connection] do |_, args|
    %w[
      db:create
      db:migrate
    ].each do |task|
      Pakyow.logger.info "[db:bootstrap] running: #{task}"
      Rake::Task[task].invoke(args[:adapter], args[:connection])
    end
  end
end
