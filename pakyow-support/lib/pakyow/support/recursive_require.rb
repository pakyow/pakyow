module Pakyow
  module Support
    module RecursiveRequire
      refine Kernel do
        # Recursively requires all *.rb files at path.
        #
        def require_recursive(require_path)
          Dir.glob(File.join(require_path, "**/*.rb")) do |path|
            require File.join("./", path)
          end
        end
      end
    end
  end
end
