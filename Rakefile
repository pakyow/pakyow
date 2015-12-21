require File.expand_path('../lib/version', __FILE__)

libs = %i[
  pakyow-support
  pakyow-core
  pakyow-presenter
  pakyow-mailer
  pakyow-rake
  pakyow-test
  pakyow-realtime
  pakyow-ui
]

rspec_libs = %i[
  pakyow-support
  pakyow-core
  pakyow-presenter
  pakyow-mailer
  pakyow-test
  pakyow-realtime
  pakyow-ui
]

task :ci do
  # require 'codeclimate-test-reporter'
  # CodeClimate::TestReporter.start

  errors = []

  rspec_libs.each do |lib|
    system(%(cd #{lib} && bundle exec rspec)) || errors << lib
  end

  fail("Errors in #{errors.join(', ')}") unless errors.empty?
end

namespace :release do
  desc 'Remove the gems'
  task :clean do
    system "rm *.gem"
  end

  desc 'Create the gems'
  task :build => [:clean] do
    system 'gem build pakyow.gemspec'

    libs.each do |lib|
      puts
      system "gem build #{lib}/#{lib}.gemspec"
    end
  end

  desc 'Create and install the gems'
  task :install => [:build] do
    libs.each do |lib|
      puts
      system "gem install #{lib}-#{Pakyow::VERSION}.gem"
    end

    puts
    system "gem install pakyow-#{Pakyow::VERSION}.gem"
  end

  desc 'Create and publish the gems'
  task :publish => [:build] do
    puts
    puts "\033[31mAre you sure you want to publish ze gems? There's no going back!"
    puts "Enter the current version number to continue...\033[0m"
    puts
    input = STDIN.gets.chomp
    puts

    if input == Pakyow::VERSION
      gems = libs.map { |lib| "#{lib}-#{Pakyow::VERSION}.gem"}

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

  desc 'Create a tag for the current version'
  task :tag do
    `git tag -a v#{Pakyow::VERSION} -m 'Pakyow #{Pakyow::VERSION}'`
  end
end
