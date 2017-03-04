module Pakyow
  module Support
    module RecursiveRequire
      DOT_RB = ".rb".freeze

      refine Kernel do
        # Recursively requires all *.rb files at path.
        #
        def require_recursive(require_path)
          return unless File.exist?(require_path)

          Dir.walk(require_path) do |path|
            next unless File.extname(path) == DOT_RB
            require path
          end
        end
      end
    end
  end
end
