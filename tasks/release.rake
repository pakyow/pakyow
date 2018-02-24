# frozen_string_literal: true

require "pakyow/version"

namespace :release do
  desc "Remove the gems"
  task :clean do
    system "rm *.gem"
  end

  desc "Create the gems"
  task build: [:clean] do
    system "gem build pakyow.gemspec"

    GEMS.each do |gem|
      puts
      system "gem build pakyow-#{gem}/pakyow-#{gem}.gemspec"
    end
  end

  desc "Create and install the gems"
  task install: [:build] do
    GEMS.each do |gem|
      puts
      system "gem install pakyow-#{gem}-#{Pakyow::VERSION}.gem"
    end

    puts
    system "gem install pakyow-#{Pakyow::VERSION}.gem"
  end

  desc "Create and publish the gems"
  task publish: [:build] do
    puts
    puts "\033[31mAre you sure you want to publish ze gems? There's no going back!"
    puts "Enter the current version number to continue...\033[0m"
    puts
    input = STDIN.gets.chomp
    puts

    if input == Pakyow::VERSION
      gems = GEMS.map { |gem| "pakyow-#{gem}-#{Pakyow::VERSION}.gem" }

      # add pakyow last
      gems << "pakyow-#{Pakyow::VERSION}.gem"

      # push!
      gems.each do |file|
        puts "Pushing #{file}"
        system "gem push #{file}"
      end
    else
      puts "Aborting"
    end
  end

  desc "Create a tag for the current version"
  task :tag do
    `git tag -a v#{Pakyow::VERSION} -m 'Pakyow #{Pakyow::VERSION}'`
  end
end
