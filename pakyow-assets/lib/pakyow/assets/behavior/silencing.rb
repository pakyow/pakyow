# frozen_string_literal: true

require "pakyow/support/extension"

module Pakyow
  module Assets
    module Behavior
      # Silences asset requests from being logged.
      #
      module Silencing
        extend Support::Extension

        apply_extension do
          after :configure do
            if config.assets.silent
              # silence asset requests
              Pakyow.silence do |connection|
                connection.path.start_with?(config.assets.prefix) || self.class.asset.instances.any? { |asset|
                  asset.logical_path == connection.path
                }
              end

              # silence requests to public files
              Pakyow.silence do |connection|
                File.file?(File.join(config.assets.public_path, connection.path))
              end
            end
          end
        end
      end
    end
  end
end
