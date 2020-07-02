# frozen_string_literal: true

require "pakyow/support/extension"

module Pakyow
  class Application
    module Behavior
      module Multiapp
        extend Support::Extension

        apply_extension do
          setting :root do
            if Pakyow.multiapp?
              File.join(Pakyow.config.multiapp_path, config.name.to_s)
            else
              Pakyow.config.root
            end
          end
        end
      end
    end
  end
end
