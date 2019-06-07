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
          on "load" do
            if config.assets.silent
              # silence asset requests
              Pakyow.silence do |connection|
                # TODO: do we need the second check?
                connection.path.start_with?(config.assets.prefix) || self.class.asset.instances.any? { |asset|
                  asset.logical_path == connection.path
                }
              end

              # silence requests to public files
              Pakyow.silence do |connection|
                # TODO: really need an in-memory directory for these files
                File.file?(File.join(config.assets.public_path, connection.path))
              end
            end
          end
        end
      end
    end
  end
end
