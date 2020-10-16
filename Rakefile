# frozen_string_literal: true

framework_paths = Pathname.new(File.expand_path("../frameworks", __FILE__)).glob("*")
package_paths = Pathname.new(File.expand_path("../packages", __FILE__)).glob("*")

GEM_PATHS = [
  Pathname.new("."),
  Pathname.new("core"),
  Pathname.new("support")
].concat(framework_paths).freeze

PACKAGE_PATHS = [].concat(package_paths).freeze

Dir.glob("tasks/*.rake").each do |tasks|
  import(tasks)
end
