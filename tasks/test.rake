# frozen_string_literal: true

require "rspec/core/rake_task"

namespace :test do
  desc "Run tests for all gems"
  task :all do
    GEMS.each do |gem|
      task = Rake::Task["test:#{gem}"]
      task.reenable
      task.invoke
    end
  end

  GEMS.each do |gem|
    RSpec::Core::RakeTask.new(gem) do |t|
      root = File.expand_path("../../", __FILE__)
      t.pattern = File.join(root, "pakyow-#{gem}/spec/**/*_spec.rb")
      t.rspec_opts = "--require #{File.join(root, "spec/spec_config")} --require #{File.join(root, "pakyow-#{gem}/spec/spec_helper")}"
      t.verbose = false
    end
  end
end
