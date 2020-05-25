# frozen_string_literal: true

require "pakyow/support/extension"

module Pakyow
  class Application
    module Behavior
      module Assets
        module Watching
          extend Support::Extension

          apply_extension do
            after "configure" do
              config.assets.extensions.each do |extension|
                # Ignore vendored assets.
                #
                Pakyow.ignore(File.join(config.assets.externals.path, "*#{extension}"))
              end
            end
          end
        end
      end
    end
  end
end
