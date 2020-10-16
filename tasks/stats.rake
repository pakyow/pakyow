# frozen_string_literal: true

namespace :stats do
  desc "Count the lines of code across all libraries"
  task :loc do
    code_paths = GEM_PATHS.map { |path|
      path.join("lib")
    } + PACKAGE_PATHS.map { |path|
      path.join("src")
    }

    system "cloc #{code_paths.join(" ")}"
  end

  desc "Count the lines of tests across all libraries"
  task :lot do
    code_paths = GEM_PATHS.map { |path|
      path.join("spec")
    } + PACKAGE_PATHS.map { |path|
      path.join("__tests__")
    }

    system "cloc #{code_paths.join(" ")}"
  end
end
