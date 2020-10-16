# frozen_string_literal: true

require "pakyow/version"

def run_with_log(command)
  puts
  puts "Running: #{command}"
  system command
end

root = File.expand_path("../../", __FILE__)

gems = GEM_PATHS.map { |gem_path|
  gem_name = ["pakyow", gem_path.basename].reject { |gem_name_part|
    gem_name_part.to_s == "."
  }.join("-")

  "#{gem_name}:#{Pakyow::VERSION}"
}.join(" ")

namespace :gems do
  desc "Remove the gems"
  task :clean do
    Bundler.with_original_env do
      run_with_log "rm -f *.gem && gem uninstall -I -x #{gems} pakyow:#{Pakyow::VERSION}"
    end
  end

  desc "Create the gems"
  task build: [:clean] do
    Bundler.with_original_env do
      run_with_log "gem build pakyow.gemspec"

      GEM_PATHS.each do |gem_path|
        gem_name = gem_path.basename

        run_with_log "cd #{gem_path} && gem build pakyow-#{gem_name}.gemspec && mv pakyow-#{gem_name}-#{Pakyow::VERSION}.gem #{root} && cd #{root}"
      end
    end
  end

  desc "Create and install the gems"
  task install: [:build] do
    Bundler.with_original_env do
      run_with_log "gem install #{gems} pakyow-#{Pakyow::VERSION}.gem"
    end
  end

  desc "Create and publish the gems"
  task publish: [:build] do
    puts
    puts "\033[31mAre you sure you want to publish these gems? There's no going back!"
    puts "Enter the current version number to continue...\033[0m"
    puts
    input = $stdin.gets.chomp
    puts

    if input == Pakyow::VERSION
      gems << "pakyow-#{Pakyow::VERSION}.gem"

      gems.each do |gem_file|
        puts "Pushing #{gem_file}"
        system "gem push #{gem_file}"
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
