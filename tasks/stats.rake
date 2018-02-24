# frozen_string_literal: true

namespace :stats do
  desc "Count the lines of code across all libraries"
  task :loc do
    all_libs = GEMS.each_with_object(["lib"]) { |gem, command|
      command << "pakyow-#{gem}/lib"
    }.join(" ")

    system "cloc #{all_libs}"
  end

  desc "Count the lines of tests across all libraries"
  task :lot do
    all_libs = GEMS.each_with_object(["spec"]) { |gem, command|
      command << "pakyow-#{gem}/spec"
    }.join(" ")

    system "cloc #{all_libs}"
  end
end
