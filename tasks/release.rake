# frozen_string_literal: true

require "pakyow/version"

def run_with_log(command)
  puts
  puts "Running: #{command}"
  system command
end

namespace :release do
  desc "Remove the gems"
  task :clean do
    Bundler.with_original_env do
      GEMS.each do |gem|
        run_with_log "rm -f *.gem && gem uninstall -I -x pakyow-#{gem} -v #{Pakyow::VERSION}"
      end

      run_with_log "gem uninstall -I -x pakyow -v #{Pakyow::VERSION}"
      run_with_log "rm -f *.gem"
    end
  end

  desc "Create the gems"
  task build: [:clean] do
    Bundler.with_original_env do
      run_with_log "gem build pakyow.gemspec"

      GEMS.each do |gem|
        run_with_log "cd pakyow-#{gem} && gem build pakyow-#{gem}.gemspec && mv pakyow-#{gem}-#{Pakyow::VERSION}.gem .. && cd .."
      end
    end
  end

  desc "Create and install the gems"
  task install: [:build] do
    Bundler.with_original_env do
      GEMS.each do |gem|
        run_with_log "gem install pakyow-#{gem}-#{Pakyow::VERSION}.gem"
      end

      run_with_log "gem install pakyow-#{Pakyow::VERSION}.gem"
    end
  end

  desc "Create and publish the gems"
  task publish: [:build] do
    puts
    puts "\033[31mAre you sure you want to publish these gems? There's no going back!"
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
