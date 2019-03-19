# frozen_string_literal: true

require "pakyow/support/extension"

module Pakyow
  class Plugin
    module Helpers
      module Rendering
        extend Support::Extension

        prepend_methods do
          def render(path = @connection.get(:__endpoint_path) || @connection.path, *args)
            super(File.join(@connection.app.class.mount_path, path), *args)
          end
        end
      end
    end
  end
end
