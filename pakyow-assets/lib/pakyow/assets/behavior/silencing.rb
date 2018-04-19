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
              Middleware::Logger.silencers << Proc.new do |path_info|
                path_info.start_with?(config.assets.prefix)
              end

              # silence requests to public files
              Middleware::Logger.silencers << Proc.new do |path_info|
                File.file?(File.join(config.assets.public_path, path_info))
              end
            end
          end
        end
      end
    end
  end
end
