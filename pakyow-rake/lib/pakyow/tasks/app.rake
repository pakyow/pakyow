# frozen_string_literal: true

namespace :pakyow do
  desc "Prepare the app by configuring and loading code"
  task :prepare do
    require "./app/setup"
    Pakyow::App.prepare(ENV["APP_ENV"] || ENV["RACK_ENV"])
  end

  desc "Stage the app by preparing and loading routes / views"
  task :stage do
    require "./app/setup"
    Pakyow::App.stage(ENV["APP_ENV"] || ENV["RACK_ENV"])
  end
end
