# frozen_string_literal: true

require "pakyow/support/extension"

module Pakyow
  module Behavior
    # Adds multiapp support to Pakyow projects. Multiapp projects allow multiple applications to be
    # run within a single environment. Combined with the `mounts` option in the `boot` command, this
    # effectively turns a project into a monorepo where applications can be developed together and
    # deployed separately.
    #
    module Multiapp
      extend Support::Extension

      apply_extension do
        setting :multiapp_path do
          File.join(config.root, "apps")
        end
      end

      class_methods do
        def multiapp?
          File.exist?(config.multiapp_path)
        end
      end
    end
  end
end
