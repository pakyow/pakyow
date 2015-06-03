version = File.read(File.expand_path("../VERSION", __FILE__)).strip
libs = %i[pakyow-support pakyow-core pakyow-presenter pakyow-mailer pakyow-rake pakyow-test pakyow-realtime]

rspec_libs = %i[pakyow-support pakyow-core pakyow-presenter pakyow-test pakyow-realtime]
minitest_libs = %i[pakyow-core pakyow-mailer]

task :ci do
  errors = []

  rspec_libs.each do |lib|
    system(%(cd #{lib} && bundle exec rspec)) || errors << lib
  end

  minitest_libs.each do |lib|
    system(%(cd #{lib} && bundle exec rake test)) || errors << lib
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
    system "gem install pakyow-#{version}.gem"
  end

  desc 'Create and publish the gems'
  task :publish => [:build] do
    puts
    puts "\033[31mAre you sure you want to publish ze gems? There's no going back!"
    puts "Enter the current version number to continue...\033[0m"
    puts
    input = STDIN.gets.chomp
    puts

    if input == version
      gems = libs.map { |lib| "#{lib}-#{version}.gem"}

      # add pakyow last
      gems << "pakyow-#{version}.gem"

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
    `git tag -a v#{version} -m 'Pakyow #{version}'`
  end
end
