# frozen_string_literal: true

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
    task gem do
      Dir.chdir "pakyow-#{gem}" do
        unless system "bundle exec rspec"
          exit $?.exitstatus
        end
      end
    end
  end
end
