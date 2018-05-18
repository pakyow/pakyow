# frozen_string_literal: true

namespace :stats do
  desc "Count the lines of code across all libraries"
  task :loc do
    all_libs = GEMS.each_with_object(["lib"]) { |gem, command|
      command << "pakyow-#{gem}/lib"
    }

    all_libs << "pakyow-js/src"

    system "cloc #{all_libs.join(" ")}"
  end

  desc "Count the lines of tests across all libraries"
  task :lot do
    all_libs = GEMS.each_with_object(["spec"]) { |gem, command|
      command << "pakyow-#{gem}/spec"
    }

    all_libs << "pakyow-js/__tests__"

    system "cloc #{all_libs.join(" ")}"
  end
end
