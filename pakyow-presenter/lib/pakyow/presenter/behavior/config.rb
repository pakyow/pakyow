# frozen_string_literal: true

require "pakyow/support/extension"
require "pakyow/support/path_version"

module Pakyow
  module Presenter
    module Behavior
      module Config
        extend Support::Extension

        apply_extension do
          configurable :presenter do
            setting :path do
              File.join(config.root, "frontend")
            end

            setting :embed_authenticity_token, true

            setting :version do
              Support::PathVersion.build(config.presenter.path)
            end
          end
        end
      end
    end
  end
end
