# frozen_string_literal: true

namespace :ci do
  desc "Build the ci environment"
  task :build, [:ruby] do |_, args|
    system "docker pull pakyow/ci-ruby-#{args[:ruby]}"
    system "docker-compose build --build-arg ruby=#{args[:ruby]}"
  end

  desc "Run a command in the ci environment"
  task :run, [:command] do |_, args|
    system "docker-compose run --rm pakyow-ci '#{args[:command]}'"
  end

  desc "Run framework tests in the ci environment"
  task :test, [:framework, :test] do |_, args|
    if args[:framework] == "js"
      system "docker-compose run --rm pakyow-ci 'cd pakyow-js && npm test #{args[:test]}'"
    else
      if args.key?(:test)
        command = "cd pakyow-#{args[:framework]} && bundle exec rspec #{args[:test]}"
        system "docker-compose run --rm -e CI=true -e GEMS='#{args[:framework]}' pakyow-ci '#{command}'"
      else
        system "docker-compose run --rm -e CI=true -e GEMS='#{args[:framework]}' pakyow-ci 'bundle exec rake'"
      end
    end
  end
end
