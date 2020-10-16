# frozen_string_literal: true

namespace :test do
  GEM_PATHS.each do |gem_path|
    gem_name = gem_path.basename
    desc "Run tests for gem: #{gem_name}"
    task gem_name, [:options] do |_, args|
      Dir.chdir(gem_path) do
        unless system("bundle exec rspec #{args[:options]}")
          exit $?.exitstatus
        end
      end
    end
  end

  PACKAGE_PATHS.each do |package_path|
    package_name = package_path.basename
    desc "Run tests for package: #{package_name}"
    task package_name, [:options] do |_, args|
      Dir.chdir(package_path) do
        unless system("yarn test #{args[:options]}")
          exit $?.exitstatus
        end
      end
    end
  end
end
