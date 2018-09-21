# frozen_string_literal: true

require "pakyow/support/extension"

module Pakyow
  class Plugin
    module Helpers
      module Rendering
        extend Support::Extension

        prepend_methods do
          def render(path = request.env["pakyow.endpoint"] || request.path, *args)
            super(File.join(@connection.app.class.mount_path, path), *args)
          end
        end
      end
    end
  end
end
